import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../customers/presentation/widgets/customer_info_card.dart';
import '../../../customers/presentation/providers/customer_activities_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/app_settings_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';

import '../providers/ticket_provider.dart';
import '../widgets/comments_section.dart';
import '../widgets/ticket_remarks_section.dart';
import '../widgets/resolve_bill_dialog.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketDetailPage({
    super.key,
    required this.ticketId,
  });

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _AgentLoadDot extends StatelessWidget {
  final Color color;

  const _AgentLoadDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

Color _agentLoadColor(int count) {
  if (count == 0) return AppColors.success;
  if (count == 1) return AppColors.warning;
  return AppColors.error;
}

String _agentLoadLabel(int count) {
  if (count == 0) return 'Free';
  if (count == 1) return 'Handling 1 ticket';
  return 'Handling $count tickets';
}

class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  Future<void> _updateStatus(String newStatus) async {
    await ref
        .read(ticketStatusUpdaterProvider.notifier)
        .updateStatus(widget.ticketId, newStatus);
  }

  Future<void> _claimTicket(Ticket ticket) async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    final success = await ref
        .read(ticketAssignerProvider.notifier)
        .assignTicket(ticket.ticketId, currentUser.id);

    if (!mounted) return;

    if (success) {
      // Keep it simple: claim only. No auto status changes or manual invalidation.
    }
  }


  Future<void> _openScreenshot(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid screenshot URL'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open screenshot'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showAssignDialog() async {
    final agentsAsync = ref.read(agentsListProvider);
    final currentUser = ref.read(authProvider);
    final isAdmin = currentUser?.isAdmin == true;
    final Map<String, int> agentLoadCounts = {};
    const completedStatuses = {'Resolved', 'Closed', 'BillProcessed'};

    // Read the raw stream to count agent load
    ref.read(rawAllTicketsStreamProvider).whenData((tickets) {
      for (final ticket in tickets) {
        final assignee = ticket.assignedTo;
        if (assignee == null || assignee.isEmpty) continue;
        if (completedStatuses.contains(ticket.status)) continue;
        agentLoadCounts[assignee] = (agentLoadCounts[assignee] ?? 0) + 1;
      }
    });

    agentsAsync.when(
      data: (agents) {
        final visibleAgents = agents.where((a) {
          final role = (a['role'] as String?)?.toLowerCase();
          if (role == null) return false;
          if (role == 'support') return true;
          if (role == 'support head') return true;
          if (isAdmin && role == 'accountant') return true;
          return false;
        }).toList();

        showDialog(
          context: context,
          builder: (dialogContext) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assign Ticket',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose an agent to hand off this ticket',
                                  style: TextStyle(
                                    color: AppColors.slate500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(LucideIcons.x),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (visibleAgents.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.slate50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.slate200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                color: AppColors.slate500,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No eligible agents found',
                                  style: TextStyle(
                                    color: AppColors.slate600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: visibleAgents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final agent = visibleAgents[index];
                              final agentId = agent['id'] as String?;
                              final loadCount =
                                  agentId == null ? 0 : (agentLoadCounts[agentId] ?? 0);
                              final loadColor = _agentLoadColor(loadCount);
                              final loadLabel = _agentLoadLabel(loadCount);
                              final displayName =
                                  agent['full_name'] ?? agent['username'] ?? 'Agent';
                              final roleLabel =
                                  (agent['role'] as String? ?? '').toUpperCase();

                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  Navigator.of(dialogContext).pop();
                                  final success = await ref
                                      .read(ticketAssignerProvider.notifier)
                                      .assignTicket(widget.ticketId, agent['id']);

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Assigned to $displayName'
                                            : 'Failed to assign',
                                      ),
                                      backgroundColor: success
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.slate200),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      _AgentLoadDot(color: loadColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.slate900,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$roleLabel • $loadLabel',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        LucideIcons.arrowRight,
                                        size: 18,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final isAdmin = currentUser?.isAdmin == true;
    final canManageAssignment = isAdmin ||
        currentUser?.isSupportHead == true ||
        currentUser?.isAgent == true;
    final ticketsAsync = ref.watch(
      singleTicketStreamProvider(widget.ticketId),
    );
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final enableSupportHeadForceResolve = appSettings == null
        ? true
        : (appSettings['enable_support_head_force_resolve'] ?? true);
    final advancedSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return MainLayout(
      currentPath: '/ticket/${widget.ticketId}',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 20,
          toolbarHeight: 60,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ticket Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              Text(
                'Conversation & history',
                style: TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
            ],
          ),
          actions: [
            if (canManageAssignment)
              IconButton(
                icon: const Icon(LucideIcons.userPlus, size: 18),
                tooltip: 'Assign Support Head',
                onPressed: _showAssignDialog,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            if (isAdmin || currentUser?.isSupportHead == true)
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 18),
                tooltip: 'Change Status',
                onSelected: _updateStatus,
                padding: EdgeInsets.zero,
                itemBuilder: (context) {
                  const allStatuses = [
                    'New',
                    'Open',
                    'In Progress',
                    'On Hold',
                    'Waiting for Customer',
                    'Resolved',
                    'Closed',
                  ];

                  final visibleStatuses =
                      advancedSettings?.visibleStatuses ?? allStatuses;

                  final options = allStatuses
                      .where((status) => visibleStatuses.contains(status))
                      .toList();

                  return options
                      .map(
                        (status) =>
                            PopupMenuItem(value: status, child: Text(status)),
                      )
                      .toList();
                },
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ticketsAsync.when(
          skipLoadingOnReload: true,
          data: (ticket) {
            if (ticket == null) {
              return const Center(child: Text('Ticket not found'));
            }
            final agentsAsync = ref.watch(agentsListProvider);
            final customerAsync = ref.watch(
              customerProvider(ticket.customerId),
            );
            final customerCompanyName = customerAsync.maybeWhen(
              data: (customer) {
                if (customer == null) return null;
                final trimmed = customer.companyName.trim();
                return trimmed.isEmpty ? null : trimmed;
              },
              orElse: () => null,
            );

            final activitiesAsync = ref.watch(
              customerActivitiesProvider(ticket.customerId),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Header Card
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate900,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatusBadge(ticket.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if ((ticket.screenshotUrl ?? '').isNotEmpty) ...[
                                _buildScreenshotSection(ticket.screenshotUrl!),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  // Created by
                                  Icon(
                                    LucideIcons.user,
                                    size: 14,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: agentsAsync.when(
                                      data: (agents) {
                                        final idToName = <String, String>{};
                                        final usernameToName = <String, String>{};
                                        for (final a in agents) {
                                          final id = a['id'] as String?;
                                          final username = a['username'] as String?;
                                          final name =
                                              (a['full_name'] ?? a['username'] ?? id)
                                                  as String?;
                                          if (id != null && name != null) {
                                            idToName[id] = name;
                                          }
                                          if (username != null && name != null) {
                                            usernameToName[username] = name;
                                          }
                                        }

                                        final isSupportHeadCreator =
                                            idToName.containsKey(ticket.createdBy) ||
                                            usernameToName.containsKey(
                                              ticket.createdBy,
                                            );

                                        if (isSupportHeadCreator) {
                                          final createdByDisplay =
                                              idToName[ticket.createdBy] ??
                                              usernameToName[ticket.createdBy] ??
                                              ticket.createdBy;
                                          return Text(
                                            createdByDisplay,
                                            style: TextStyle(color: AppColors.slate600, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }

                                        // If not an agent, show Company Name
                                        return Text(
                                          customerCompanyName ?? ticket.createdBy,
                                          style: const TextStyle(
                                            color: AppColors.slate900,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                      loading: () => Text(
                                        ticket.createdBy,
                                        style: TextStyle(color: AppColors.slate600, fontSize: 13),
                                      ),
                                      error: (_, __) => Text(
                                        ticket.createdBy,
                                        style: TextStyle(color: AppColors.slate600, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Created time
                                  Icon(
                                    LucideIcons.clock,
                                    size: 14,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ticket.createdAt != null
                                        ? timeago.format(ticket.createdAt!.toLocal())
                                        : 'Unknown',
                                    style: TextStyle(color: AppColors.slate500, fontSize: 13),
                                  ),
                                ],
                              ),
                              if ((ticket.contactPhone ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.phone,
                                      size: 14,
                                      color: AppColors.slate400,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Caller:',
                                      style: TextStyle(
                                        color: AppColors.slate500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: SelectableText(
                                        ticket.contactPhone!,
                                        style: const TextStyle(
                                          color: AppColors.slate900,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Assignee row
                              agentsAsync.when(
                                data: (agents) {
                                  final idToName = <String, String>{};
                                  for (final a in agents) {
                                    final id = a['id'] as String?;
                                    if (id == null) continue;
                                    idToName[id] =
                                        (a['full_name'] ?? a['username'] ?? id)
                                            as String;
                                  }

                                  final assigneeName =
                                      (ticket.assignedTo == null ||
                                          ticket.assignedTo!.isEmpty)
                                      ? 'Unassigned'
                                      : (idToName[ticket.assignedTo!] ??
                                            ticket.assignedTo!);

                                  return Row(
                                    children: [
                                      Icon(
                                        LucideIcons.userCheck,
                                        size: 14,
                                        color: AppColors.slate400,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Assigned to: ',
                                        style: TextStyle(color: AppColors.slate500, fontSize: 13),
                                      ),
                                      Text(
                                        assigneeName,
                                        style: TextStyle(
                                          color: AppColors.slate700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (canManageAssignment) ...[
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: _showAssignDialog,
                                          borderRadius: BorderRadius.circular(4),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Text(
                                              assigneeName == 'Unassigned'
                                                  ? 'Assign'
                                                  : 'Change',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                              
                              if ([
                                'BillRaised',
                                'BillProcessed',
                                'Resolved',
                                'Closed',
                              ].contains(ticket.status)) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.slate200),
                                  ),
                                  child: Text(
                                    'Bill Amount: ₹${ticket.billAmount ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              
                              // Description
                              if ((ticket.description ?? '').trim().isEmpty)
                                const Text(
                                  'No description provided',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.slate500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                MarkdownBody(
                                  data: ticket.description!,
                                  styleSheet:
                                      MarkdownStyleSheet.fromTheme(
                                        Theme.of(context),
                                      ).copyWith(
                                        p: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: AppColors.slate700,
                                        ),
                                      ),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Tags row
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                    icon: LucideIcons.flag,
                                    label: 'Priority',
                                    value: ticket.priority ?? 'Normal',
                                    color: _getPriorityColor(ticket.priority),
                                    compact: true,
                                  ),
                                  if (ticket.category != null)
                                    _buildInfoChip(
                                      icon: LucideIcons.tag,
                                      label: 'Category',
                                      value: ticket.category!,
                                      color: AppColors.info,
                                      compact: true,
                                    ),
                                  const SizedBox(width: 12),
                                  if (advancedSettings != null)
                                    _buildInfoChip(
                                      icon: LucideIcons.clock,
                                      label: 'Response time',
                                      value: _formatResponseTimeTarget(
                                        advancedSettings.slaMinutesForPriority(
                                          ticket.priority,
                                        ),
                                      ),
                                      color: AppColors.slate500,
                                      compact: true,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if ((ticket.assignedTo == null ||
                          ticket.assignedTo!.isEmpty) &&
                      (currentUser?.isSupport == true ||
                          currentUser?.isHR == true ||
                          currentUser?.isProjectCoordinator == true ||
                          currentUser?.isSupportHead == true ||
                          currentUser?.isAgent == true))
                    AppButton(
                      label: 'Claim Ticket',
                      icon: LucideIcons.userCheck,
                      onPressed: () => _claimTicket(ticket),
                    ),
                  if (ticket.assignedTo == currentUser?.id &&
                      ![
                        'BillRaised',
                        'BillProcessed',
                        'Closed',
                        'Resolved',
                      ].contains(ticket.status))
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Resolve Actions
                        AppButton.secondary(
                          label: 'Resolve',
                          icon: LucideIcons.check,
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Resolve Ticket'),
                                content: const Text(
                                  'Are you sure you want to resolve this ticket? This will mark it as completed.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                    child: const Text('Resolve'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              _updateStatus('Resolved');
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        AppButton(
                          label: 'Resolve & Raise Bill',
                          icon: LucideIcons.fileCheck,
                          onPressed: () async {
                            await showDialog<bool>(
                              context: context,
                              builder: (context) => ResolveBillDialog(
                                ticketId: ticket.ticketId,
                                onResolve: (ticketId, amount) async {
                                  return ref
                                      .read(
                                        ticketStatusUpdaterProvider.notifier,
                                      )
                                      .resolveAndBill(ticketId, amount);
                                },
                              ),
                            );

                            if (!mounted) return;
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Charge History
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'In-Charge History',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ref
                            .watch(
                              ticketAssignmentHistoryProvider(ticket.ticketId),
                            )
                            .when(
                              data: (events) {
                                final agentsAsync = ref.watch(
                                  agentsListProvider,
                                );

                                return agentsAsync.when(
                                  data: (agents) {
                                    final agentNames = <String, String>{};
                                    final usernameToName = <String, String>{};
                                    for (final a in agents) {
                                      final id = a['id'] as String?;
                                      final username = a['username'] as String?;
                                      final name =
                                          (a['full_name'] ??
                                                  a['username'] ??
                                                  id)
                                              as String?;
                                      if (id == null) continue;
                                      agentNames[id] = name ?? id;
                                      if (username != null && name != null) {
                                        usernameToName[username] = name;
                                      }
                                    }

                                    String resolveDisplayName(String value) {
                                      return agentNames[value] ??
                                          usernameToName[value] ??
                                          (value == ticket.createdBy &&
                                                  customerCompanyName != null
                                              ? customerCompanyName
                                              : value);
                                    }

                                    final currentHandlerName =
                                        (ticket.assignedTo == null ||
                                            ticket.assignedTo!.isEmpty)
                                        ? null
                                        : resolveDisplayName(
                                            ticket.assignedTo!,
                                          );

                                    final headerRows = <Widget>[
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.user,
                                            size: 13,
                                            color: AppColors.slate600,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Ticket raised by: ${resolveDisplayName(ticket.createdBy)}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.slate700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ref
                                          .watch(
                                            ticketFirstAssignedToProvider(
                                              ticket.ticketId,
                                            ),
                                          )
                                          .when(
                                            data: (firstAssignedId) {
                                              if (firstAssignedId == null ||
                                                  firstAssignedId.isEmpty) {
                                                return const SizedBox.shrink();
                                              }
                                              return Row(
                                                children: [
                                                  const Icon(
                                                    LucideIcons.userCheck,
                                                    size: 13,
                                                    color: AppColors.slate600,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'First assigned to: ${resolveDisplayName(firstAssignedId)}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color:
                                                            AppColors.slate700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                            loading: () =>
                                                const SizedBox.shrink(),
                                            error: (_, __) =>
                                                const SizedBox.shrink(),
                                          ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            LucideIcons.userCheck,
                                            size: 13,
                                            color: AppColors.slate600,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Handled by now: ${currentHandlerName ?? 'Unassigned'}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.slate700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ];

                                    if (events.isEmpty) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [...headerRows],
                                      );
                                    }

                                    final sortedEvents =
                                        List<Map<String, dynamic>>.from(events);
                                    sortedEvents.sort((a, b) {
                                      DateTime? parse(dynamic v) {
                                        if (v is DateTime) return v;
                                        if (v is String) {
                                          return DateTime.tryParse(v);
                                        }
                                        return null;
                                      }

                                      final atA = parse(a['assigned_at']);
                                      final atB = parse(b['assigned_at']);
                                      if (atA == null && atB == null) return 0;
                                      if (atA == null) return -1;
                                      if (atB == null) return 1;
                                      return atA.compareTo(atB);
                                    });

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ...headerRows,
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        ...sortedEvents.map((e) {
                                          DateTime? parse(dynamic v) {
                                            if (v is DateTime) return v;
                                            if (v is String) {
                                              return DateTime.tryParse(v);
                                            }
                                            return null;
                                          }

                                          final fromId = e['from'] as String?;
                                          final toId = e['to'] as String?;
                                          final assignedById =
                                              e['assigned_by'] as String?;
                                          // unused note variable removed

                                          final completed =
                                              (e['completed'] as bool?) == true;
                                          final assignedAt = parse(
                                            e['assigned_at'],
                                          );
                                          final completedAt = parse(
                                            e['completed_at'],
                                          );

                                          // unused names removed

                                          final timeLabel = completed
                                              ? (completedAt == null
                                                    ? null
                                                    : 'Completed ${timeago.format(completedAt.toLocal())}')
                                              : (assignedAt == null
                                                    ? null
                                                    : timeago.format(
                                                        assignedAt.toLocal(),
                                                      ));

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.slate50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Wrap(
                                                          crossAxisAlignment:
                                                              WrapCrossAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              resolveDisplayName(
                                                                fromId ?? 'Unknown',
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .slate700,
                                                              ),
                                                            ),
                                                            const Padding(
                                                              padding:
                                                                  EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 6,
                                                              ),
                                                              child: Icon(
                                                                LucideIcons
                                                                    .arrowRight,
                                                                size: 12,
                                                                color: AppColors
                                                                    .slate400,
                                                              ),
                                                            ),
                                                            Text(
                                                              resolveDisplayName(
                                                                toId ?? 'Unknown',
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .slate700,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (timeLabel != null)
                                                        Text(
                                                          timeLabel,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            color: AppColors
                                                                .slate500,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'By ${resolveDisplayName(assignedById ?? 'Unknown')}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.slate500,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Info
                  if (customerAsync.hasValue && customerAsync.value != null)
                    CustomerInfoCard(
                      customer: customerAsync.value!,
                    ),

                  const SizedBox(height: 16),

                  // Customer Activity
                  if (activitiesAsync.hasValue)
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (activitiesAsync.value!.isEmpty)
                            const Text(
                              'No recent activity',
                              style: TextStyle(
                                color: AppColors.slate500,
                                fontSize: 13,
                              ),
                            )
                          else
                            Column(
                              children: activitiesAsync.value!.take(3).map((a) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.subject,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.slate900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${a.type} · ${timeago.format(a.occurredAt.toLocal())}',
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
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Override Resolve Button (Support Head only, feature-flagged)
                  if (enableSupportHeadForceResolve &&
                      currentUser?.isSupportHead == true &&
                      ticket.status != 'BillRaised' &&
                      ticket.status != 'BillProcessed')
                    AppButton(
                      label: 'Force Resolve & Send to Billing',
                      icon: LucideIcons.zap,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);

                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Override Resolve'),
                            content: const Text(
                              'This will bypass the normal workflow and send the ticket directly to billing. Are you sure?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                ),
                                child: const Text('Force Resolve'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true || !mounted) return;

                        final error = await ref
                            .read(ticketStatusUpdaterProvider.notifier)
                            .updateStatus(ticket.ticketId, 'BillRaised');

                        if (!mounted) return;

                        final success = error == null;

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Ticket sent to billing'
                                  : 'Failed to update status: $error',
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Remarks Section
                  TicketRemarksSection(
                    ticketId: ticket.ticketId,
                    currentStage: ticket.status,
                  ),
                  const SizedBox(height: 32),

                  // Comments Section
                  SizedBox(
                    height: 600,
                    child: CommentsSection(
                      ticketId: ticket.ticketId,
                      currentUserName:
                          ref.watch(authProvider)?.username ?? 'Unknown',
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error: $err',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  String _formatResponseTimeTarget(int minutes) {
    if (minutes < 60) return '$minutes min';
    if (minutes < 1440) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '${hours}h';
      return '${hours}h ${mins}m';
    }
    final days = minutes ~/ 1440;
    final remainingMinutes = minutes % 1440;
    if (remainingMinutes == 0) return '${days}d';
    final hours = remainingMinutes ~/ 60;
    if (hours == 0) return '${days}d';
    return '${days}d ${hours}h';
  }

  Widget _buildStatusBadge(String status) {
    StatusVariant variant;
    if (status.contains('New') || status.contains('Open')) {
      variant = StatusVariant.info;
    } else if (status.contains('Progress')) {
      variant = StatusVariant.warning;
    } else if (status.contains('Resolved')) {
      variant = StatusVariant.success;
    } else {
      variant = StatusVariant.neutral;
    }
    return StatusBadge(label: status, variant: variant);
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 16, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              color: AppColors.slate600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    if (priority == null) return AppColors.slate400;
    switch (priority.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.slate400;
    }
  }

  Widget _buildScreenshotSection(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Screenshot',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.slate200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Unable to load screenshot',
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => _openScreenshot(url),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.externalLink,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Open full size',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}







