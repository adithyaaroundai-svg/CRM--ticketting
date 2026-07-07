import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/layout/main_layout.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_card.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../providers/productivity_providers.dart';
import '../../domain/entities/deal.dart';

class DealsPage extends ConsumerStatefulWidget {
  const DealsPage({super.key});

  @override
  ConsumerState<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends ConsumerState<DealsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealsProvider);
    final customersAsync = ref.watch(customersListProvider);
    final currentUser = ref.watch(authProvider);
    final canEdit =
        currentUser?.isAdmin == true ||
        currentUser?.isSupportHead == true ||
        currentUser?.isAccountant == true;

    return MainLayout(
      currentPath: '/deals',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sales Pipeline',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  if (canEdit)
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('New Deal'),
                      onPressed: () => _showDealDialog(context, ref),
                    ),
                ],
              ),
            ),

            // Pipeline stats
            dealsAsync.when(
              data: (deals) {
                final totalValue = deals
                    .where((d) => d.stage != 'lost')
                    .fold<double>(0, (sum, d) => sum + d.value);
                final wonValue = deals
                    .where((d) => d.stage == 'won')
                    .fold<double>(0, (sum, d) => sum + d.value);
                final activeDeals = deals
                    .where((d) => !['won', 'lost'].contains(d.stage))
                    .length;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Pipeline Value',
                        value: currencyFormat.format(totalValue),
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'Won Deals',
                        value: currencyFormat.format(wonValue),
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        label: 'Active Deals',
                        value: activeDeals.toString(),
                        color: AppColors.info,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Kanban Board
            Expanded(
              child: dealsAsync.when(
                data: (deals) {
                  return customersAsync.when(
                    data: (customers) {
                      final customerMap = {
                        for (var c in customers) c.id: c.companyName,
                      };

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: Deal.stages.map((stage) {
                            final stageDeals = deals
                                .where((d) => d.stage == stage)
                                .toList();
                            final stageValue = stageDeals.fold<double>(
                              0,
                              (sum, d) => sum + d.value,
                            );

                            return _KanbanColumn(
                              stage: stage,
                              deals: stageDeals,
                              customerMap: customerMap,
                              stageValue: stageValue,
                              currencyFormat: currencyFormat,
                              canEdit: canEdit,
                              onDealTap: (deal) =>
                                  _showDealDialog(context, ref, deal: deal),
                              onStageChange: (deal, newStage) {
                                ref
                                    .read(dealControllerProvider.notifier)
                                    .updateDealStage(deal.id, newStage);
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDealDialog(BuildContext context, WidgetRef ref, {Deal? deal}) {
    final isEdit = deal != null;
    final titleController = TextEditingController(text: deal?.title ?? '');
    final valueController = TextEditingController(
      text: deal?.value.toString() ?? '0',
    );
    final descController = TextEditingController(text: deal?.description ?? '');
    String selectedStage = deal?.stage ?? 'new';
    String? selectedCustomerId = deal?.customerId;
    String? selectedAgentId = deal?.assignedTo;
    DateTime? expectedClose = deal?.expectedCloseDate;

    final customersAsync = ref.read(customersListProvider);
    final agentsAsync = ref.read(agentsListProvider);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Deal' : 'New Deal'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Deal Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      customersAsync.maybeWhen(
                        data: (customers) => DropdownButtonFormField<String>(
                          initialValue: selectedCustomerId,
                          decoration: const InputDecoration(
                            labelText: 'Customer',
                            border: OutlineInputBorder(),
                          ),
                          items: customers.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.companyName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCustomerId = value;
                            });
                          },
                        ),
                        orElse: () => const LinearProgressIndicator(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valueController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Deal Value (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStage,
                        decoration: const InputDecoration(
                          labelText: 'Stage',
                          border: OutlineInputBorder(),
                        ),
                        items: Deal.stages.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(Deal.stageLabel(s)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStage = value ?? 'new';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      agentsAsync.maybeWhen(
                        data: (agents) => DropdownButtonFormField<String?>(
                          initialValue: selectedAgentId,
                          decoration: const InputDecoration(
                            labelText: 'Assigned To',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Unassigned'),
                            ),
                            ...agents.map((a) {
                              return DropdownMenuItem(
                                value: a['id'] as String,
                                child: Text(a['username'] as String),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedAgentId = value;
                            });
                          },
                        ),
                        orElse: () => const LinearProgressIndicator(),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          expectedClose != null
                              ? 'Expected Close: ${DateFormat.yMMMd().format(expectedClose!)}'
                              : 'Set Expected Close Date',
                        ),
                        trailing: const Icon(LucideIcons.calendar),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: expectedClose ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              expectedClose = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isEdit)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, ref, deal.id);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isEmpty ||
                        selectedCustomerId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title and Customer are required'),
                        ),
                      );
                      return;
                    }

                    final value = double.tryParse(valueController.text) ?? 0;

                    if (isEdit) {
                      ref
                          .read(dealControllerProvider.notifier)
                          .updateDeal(
                            id: deal.id,
                            title: titleController.text,
                            stage: selectedStage,
                            value: value,
                            description: descController.text.isEmpty
                                ? null
                                : descController.text,
                            assignedTo: selectedAgentId,
                            expectedCloseDate: expectedClose,
                          );
                    } else {
                      ref
                          .read(dealControllerProvider.notifier)
                          .createDeal(
                            customerId: selectedCustomerId!,
                            title: titleController.text,
                            stage: selectedStage,
                            value: value,
                            description: descController.text.isEmpty
                                ? null
                                : descController.text,
                            assignedTo: selectedAgentId,
                            expectedCloseDate: expectedClose,
                          );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String dealId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deal'),
        content: const Text('Are you sure you want to delete this deal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(dealControllerProvider.notifier).deleteDeal(dealId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String stage;
  final List<Deal> deals;
  final Map<String, String> customerMap;
  final double stageValue;
  final NumberFormat currencyFormat;
  final bool canEdit;
  final void Function(Deal) onDealTap;
  final void Function(Deal, String) onStageChange;

  const _KanbanColumn({
    required this.stage,
    required this.deals,
    required this.customerMap,
    required this.stageValue,
    required this.currencyFormat,
    required this.canEdit,
    required this.onDealTap,
    required this.onStageChange,
  });

  Color get stageColor {
    switch (stage) {
      case 'new':
        return AppColors.info;
      case 'qualified':
        return AppColors.primary;
      case 'proposal':
        return Colors.orange;
      case 'negotiation':
        return Colors.purple;
      case 'won':
        return AppColors.success;
      case 'lost':
        return AppColors.error;
      default:
        return AppColors.slate500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stageColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: stageColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: stageColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Deal.stageLabel(stage),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: stageColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deals.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: stageColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Value summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                vertical: BorderSide(color: stageColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Text(
              currencyFormat.format(stageValue),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate600,
              ),
            ),
          ),

          // Deal Cards
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: deals.isEmpty
                  ? Center(
                      child: Text(
                        'No deals',
                        style: TextStyle(
                          color: AppColors.slate400,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: deals.length,
                      itemBuilder: (context, index) {
                        final deal = deals[index];
                        return _DealCard(
                          deal: deal,
                          customerName:
                              customerMap[deal.customerId] ?? 'Unknown',
                          currencyFormat: currencyFormat,
                          canEdit: canEdit,
                          onTap: () => onDealTap(deal),
                          onStageChange: (newStage) =>
                              onStageChange(deal, newStage),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Deal deal;
  final String customerName;
  final NumberFormat currencyFormat;
  final bool canEdit;
  final VoidCallback onTap;
  final void Function(String) onStageChange;

  const _DealCard({
    required this.deal,
    required this.customerName,
    required this.currencyFormat,
    required this.canEdit,
    required this.onTap,
    required this.onStageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: InkWell(
          onTap: canEdit ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.building2,
                      size: 12,
                      color: AppColors.slate500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFormat.format(deal.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.success,
                      ),
                    ),
                    if (deal.expectedCloseDate != null)
                      Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 12,
                            color: AppColors.slate400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.MMMd().format(deal.expectedCloseDate!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (canEdit && !['won', 'lost'].contains(deal.stage)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (deal.stage != 'new')
                        _MoveButton(
                          icon: LucideIcons.chevronLeft,
                          onTap: () {
                            final idx = Deal.stages.indexOf(deal.stage);
                            if (idx > 0) {
                              onStageChange(Deal.stages[idx - 1]);
                            }
                          },
                        ),
                      const Spacer(),
                      if (deal.stage != 'lost' && deal.stage != 'won')
                        _MoveButton(
                          icon: LucideIcons.chevronRight,
                          onTap: () {
                            final idx = Deal.stages.indexOf(deal.stage);
                            if (idx < Deal.stages.length - 1) {
                              onStageChange(Deal.stages[idx + 1]);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MoveButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.slate200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: AppColors.slate600),
      ),
    );
  }
}
