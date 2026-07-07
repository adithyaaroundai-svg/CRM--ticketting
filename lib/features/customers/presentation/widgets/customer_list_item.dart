import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/components/app_card.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_notes_provider.dart';
import '../providers/customer_contacts_provider.dart';
import '../providers/customer_activities_provider.dart';

class CustomerListItem extends ConsumerWidget {
  final Customer customer;
  final VoidCallback onTap;
  final bool expanded;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simple health heuristic based on AMC status and days remaining
    final bool amcActive = customer.isAmcActive;
    final int daysRemaining = customer.amcDaysRemaining;

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

    final notesAsync = ref.watch(customerNotesProvider(customer.id));
    final hasPinnedNotes = notesAsync.maybeWhen(
      data: (notes) =>
          notes.any((note) => (note['is_pinned'] as bool?) ?? false),
      orElse: () => false,
    );

    final contactsAsync = ref.watch(customerContactsProvider(customer.id));
    final hasContacts = contactsAsync.maybeWhen(
      data: (contacts) => contacts.isNotEmpty,
      orElse: () => false,
    );

    final activitiesAsync = ref.watch(customerActivitiesProvider(customer.id));
    final hasRecentActivity = activitiesAsync.maybeWhen(
      data: (activities) {
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        return activities.any(
          (activity) => activity.occurredAt.isAfter(cutoff),
        );
      },
      orElse: () => false,
    );

    final dateFormatter = DateFormat('d MMM y');
    final amcDateLabel = customer.amcExpiryDate != null
        ? dateFormatter.format(customer.amcExpiryDate!)
        : 'Not set';
    final phoneLabel = customer.primaryPhone ?? 'No phone on file';

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: expanded ? 18 : 12,
        vertical: expanded ? 18 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                            customer.companyName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: customer.amcExpiryDate != null
                                  ? AppColors.primary
                                  : AppColors.slate900,
                            ),
                          ),
                          if (customer.amcExpiryDate != null)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              height: 2,
                              width: 32,
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          if (customer.contactPerson != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              customer.contactPerson!,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!expanded) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildCompactStatusRow(healthLabel, healthColor),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.slate400,
                    ),
                  ],
                ),
                if (!expanded)
                  const SizedBox(height: 2)
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildStatusPill(
                        label: customer.isAmcActive ? 'AMC Active' : 'AMC Expired',
                        color: customer.isAmcActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      _buildStatusPill(label: healthLabel, color: healthColor),
                      if (hasPinnedNotes)
                        _buildStatusPill(
                          label: 'Pinned notes',
                          color: AppColors.info,
                        ),
                      if (hasContacts)
                        _buildStatusPill(
                          label: 'Contacts',
                          color: AppColors.info,
                        ),
                      if (hasRecentActivity)
                        _buildStatusPill(
                          label: 'Recent activity',
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    icon: LucideIcons.calendarDays,
                    label: 'AMC expiry',
                    value: amcDateLabel,
                    valueColor:
                        customer.isAmcActive ? AppColors.slate700 : AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: LucideIcons.shieldCheck,
                    label: 'AMC status',
                    value: customer.isAmcActive ? 'Active' : 'Expired',
                    valueColor:
                        customer.isAmcActive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: LucideIcons.phone,
                    label: 'Phone',
                    value: phoneLabel,
                    valueColor: AppColors.slate800,
                  ),
                  if (customer.phoneNumbers.length > 1) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Other numbers: ${customer.phoneNumbers.skip(1).take(2).join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusRow(String healthLabel, Color healthColor) {
    final widgets = <Widget>[
      _buildStatusPill(
        label: customer.isAmcActive ? 'AMC Active' : 'AMC Expired',
        color: customer.isAmcActive ? AppColors.success : AppColors.error,
      ),
      const SizedBox(width: 6),
      _buildStatusPill(label: healthLabel, color: healthColor),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: widgets,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = AppColors.slate700,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.slate400),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.slate500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
