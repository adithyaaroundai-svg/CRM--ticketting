import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/app_settings_provider.dart';

const Set<String> _stageBilledStatuses = {
  'billprocessed',
  'closed',
};

/// Converts a DateTime to local time for display
DateTime _toLocalTime(DateTime dateTime) {
  if (dateTime.isUtc) {
    return dateTime.toLocal();
  }
  return dateTime;
}

enum TicketCardLayout {
  standard, // Vertical lists: Center Company Name
  compact, // Top Section: Title Left, Overdue Right, Company below Badge
}

class TicketCardWithAmc extends ConsumerWidget {
  final Ticket ticket;
  final bool highlightPriorityCustomer;
  final TicketCardLayout layout;
  final bool forceClaimButton;
  final bool showRaisedByBubble;
  final bool emphasizeUnclaimedEdge;

  const TicketCardWithAmc({
    super.key,
    required this.ticket,
    this.highlightPriorityCustomer = false,
    this.layout = TicketCardLayout.standard,
    this.forceClaimButton = false,
    this.showRaisedByBubble = false,
    this.emphasizeUnclaimedEdge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(ticketCustomerProvider(ticket.customerId));
    final agentsAsync = ref.watch(agentsListProvider);
    final isCustomerLoading = customerAsync.isLoading;
    final advancedSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    Color? cardBackgroundColor;
    Color? borderColor;
    Color? ribbonColor;
    Color? ribbonTextColor;
    String? ribbonLabel;
    IconData? ribbonIcon;

    if (!isCustomerLoading &&
        (ticket.assignedTo == null || ticket.assignedTo!.isEmpty)) {
      final slaColors = _getSlaColors(ticket, advancedSettings);
      cardBackgroundColor = slaColors['background'];
      borderColor = slaColors['border'];
    }

    final isPriorityCustomer =
        highlightPriorityCustomer ||
        customerAsync.maybeWhen(
          data: (data) {
            if (data == null) return false;
            return Customer.fromJson(data).isAmcActive;
          },
          orElse: () => false,
        );

    if (customerAsync.hasValue && customerAsync.value != null) {
      final customer = Customer.fromJson(customerAsync.value!);
      if (customer.isAmcActive) {
        cardBackgroundColor = context.isDarkMode ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFFDBEAFE);
        borderColor = context.isDarkMode ? Colors.blue.withValues(alpha: 0.3) : const Color(0xFF60A5FA);
        ribbonColor = const Color(0xFF1D4ED8); // solid blue ribbon
        ribbonTextColor = Colors.white;
        ribbonLabel = 'AMC Priority';
        ribbonIcon = LucideIcons.sparkles;
      } else {
        cardBackgroundColor = context.adaptiveCard;
        borderColor = context.adaptiveBorder;
      }
    } else if (isPriorityCustomer) {
      cardBackgroundColor ??= context.adaptiveCard;
      borderColor ??= context.adaptiveBorder;
      ribbonColor ??= const Color(0xFFF1F5F9);
      ribbonTextColor ??= AppColors.slate700;
      ribbonLabel ??= 'Priority';
      ribbonIcon ??= LucideIcons.star;
    }

    final backgroundColor = cardBackgroundColor ?? context.adaptiveCard;
    final bool isDarkSurface = context.isDarkMode;
    final Color headingColor = isDarkSurface
        ? Colors.white
        : AppColors.slate900;
    final currentUser = ref.watch(authProvider);
    final isMyTicket = currentUser?.id == ticket.assignedTo;
    final roleLower = currentUser?.role.trim().toLowerCase() ?? '';
    final canClaimTicket = forceClaimButton ||
        currentUser?.isSupport == true ||
        currentUser?.isSupportHead == true ||
        currentUser?.isAgent == true ||
        roleLower.contains('support');
    final isCompactLayout = layout == TicketCardLayout.compact;

    final hasRibbon = ribbonLabel != null;

    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;
    final disableCardTap = canClaimTicket && isUnassigned;

    final raisedBy = ticket.createdBy.trim();
    String raisedByDisplay = raisedBy;
    String? raisedByColorHex;

    if (raisedBy.isNotEmpty && raisedBy.toLowerCase() != 'unknown') {
      final agents = agentsAsync.value ?? [];
      final agent = agents.where((a) => a['id'] == raisedBy).firstOrNull;
      if (agent != null) {
        raisedByDisplay = agent['full_name'] ?? agent['username'] ?? raisedBy;
        raisedByColorHex = agent['display_color'];
      } else {
        final customer = customerAsync.value;
        if (customer != null) {
          raisedByDisplay = customer['company_name'] ?? customer['contact_name'] ?? raisedBy;
          raisedByColorHex = customer['display_color'];
        }
      }
    }

    final shouldShowRaisedBy = showRaisedByBubble &&
        raisedByDisplay.isNotEmpty &&
        raisedByDisplay.toLowerCase() != 'unknown';
    final shouldShowUnclaimedGlow = emphasizeUnclaimedEdge && isUnassigned;

    Color _hexToColor(String hex) {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    }

    final card = Container(
      margin: EdgeInsets.only(right: shouldShowUnclaimedGlow ? 110 : 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: isDarkSurface ? [] : [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              disableCardTap
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: isCompactLayout
                          ? _buildCompactContent(
                              context: context,
                              ref: ref,
                              headingColor: headingColor,
                              customerAsync: customerAsync,
                              canClaimTicket: canClaimTicket,
                              isMyTicket: isMyTicket,
                              hasRibbon: hasRibbon,
                              agents: agentsAsync.value ?? [],
                            )
                          : _buildStandardContent(
                              context: context,
                              ref: ref,
                              headingColor: headingColor,
                              customerAsync: customerAsync,
                              canClaimTicket: canClaimTicket,
                              isMyTicket: isMyTicket,
                              hasRibbon: hasRibbon,
                              agents: agentsAsync.value ?? [],
                            ),
                    )
                  : InkWell(
                      onTap: () => context.push('/ticket/${ticket.ticketId}'),
                      borderRadius: BorderRadius.circular(9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: isCompactLayout
                            ? _buildCompactContent(
                                context: context,
                                ref: ref,
                                headingColor: headingColor,
                                customerAsync: customerAsync,
                                canClaimTicket: canClaimTicket,
                                isMyTicket: isMyTicket,
                                hasRibbon: hasRibbon,
                                agents: agentsAsync.value ?? [],
                              )
                            : _buildStandardContent(
                                context: context,
                                ref: ref,
                                headingColor: headingColor,
                                customerAsync: customerAsync,
                                canClaimTicket: canClaimTicket,
                                isMyTicket: isMyTicket,
                                hasRibbon: hasRibbon,
                                agents: agentsAsync.value ?? [],
                              ),
                      ),
                    ),
              if (ribbonLabel != null)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _buildRibbon(
                    label: ribbonLabel,
                    color: ribbonColor ?? Colors.white,
                    textColor: ribbonTextColor ?? AppColors.slate700,
                    icon: ribbonIcon,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shouldShowRaisedBy)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              raisedByDisplay,
              style: TextStyle(
                fontSize: 9.75,
                fontWeight: FontWeight.w600,
                color: raisedByColorHex != null ? _hexToColor(raisedByColorHex) : AppColors.slate600,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (shouldShowUnclaimedGlow)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: const _UnclaimedGlassTag(),
                ),
              card,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRibbon({
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 8.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getSlaColors(Ticket ticket, dynamic advancedSettings) {
    final now = DateTime.now();
    final slaDue = _computeTargetDue(ticket, advancedSettings);

    if (slaDue != null) {
      final minutes = slaDue.difference(now).inMinutes;

      if (minutes >= 60) {
        return {
          'background': AppColors.success.withValues(alpha: 0.08),
          'border': AppColors.success.withValues(alpha: 0.3),
        };
      } else if (minutes >= 0) {
        return {
          'background': AppColors.warning.withValues(alpha: 0.08),
          'border': AppColors.warning.withValues(alpha: 0.3),
        };
      } else {
        return {
          'background': AppColors.error.withValues(alpha: 0.08),
          'border': AppColors.error.withValues(alpha: 0.3),
        };
      }
    }

    final ageMinutes = now.difference(ticket.createdAt ?? now).inMinutes;
    if (ageMinutes < 60) {
      return {
        'background': AppColors.success.withValues(alpha: 0.04),
        'border': AppColors.success.withValues(alpha: 0.2),
      };
    } else if (ageMinutes < 4 * 60) {
      return {
        'background': AppColors.warning.withValues(alpha: 0.04),
        'border': AppColors.warning.withValues(alpha: 0.2),
      };
    } else {
      return {
        'background': AppColors.error.withValues(alpha: 0.04),
        'border': AppColors.error.withValues(alpha: 0.2),
      };
    }
  }

  DateTime? _computeTargetDue(Ticket ticket, dynamic advancedSettings) {
    if (ticket.slaDue != null) {
      return ticket.slaDue;
    }

    if (advancedSettings == null) return null;

    try {
      final minutes = advancedSettings.slaMinutesForPriority(ticket.priority);
      if (minutes <= 0) return null;
      final createdAt = ticket.createdAt;
      if (createdAt == null) return null;
      return createdAt.add(Duration(minutes: minutes));
    } catch (_) {
      return null;
    }
  }


  Widget _buildStandardContent({
    required BuildContext context,
    required WidgetRef ref,
    required Color headingColor,
    required AsyncValue<Map<String, dynamic>?> customerAsync,
    required bool canClaimTicket,
    required bool isMyTicket,
    required bool hasRibbon,
    required List<Map<String, dynamic>> agents,
  }) {
    final customer = customerAsync.maybeWhen(
      data: (data) => data == null ? null : Customer.fromJson(data),
      orElse: () => null,
    );
    final companyName = customer?.companyName.trim().isEmpty == true
        ? null
        : customer?.companyName;
    final referenceDateRaw = ticket.updatedAt ?? ticket.createdAt;
    final referenceDate =
        referenceDateRaw == null ? null : _toLocalTime(referenceDateRaw);
    final createdTimestamp = referenceDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(referenceDate)
        : null;
    final createdRelative =
        referenceDate != null
            ? timeago.format(
                referenceDate,
                clock: DateTime.now(),
              )
            : null;
    final actionButton = _buildActionButtons(
      context: context,
      ref: ref,
      canClaimTicket: canClaimTicket,
      isMyTicket: isMyTicket,

    );
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;

    final statusPill = _buildMinimalStatusPill(
      context: context,
      status: ticket.status,
      isUnassigned: isUnassigned,
      isMyTicket: isMyTicket,
      agents: agents,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyName != null || createdTimestamp != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: companyName != null
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.building2,
                            size: 18,
                            color: context.adaptiveSlate500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 14.25,
                                fontWeight: FontWeight.w800,
                                color: headingColor,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'No company linked',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: context.adaptiveSlate500,
                        ),
                      ),
              ),
              if (createdTimestamp != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      createdTimestamp,
                      style: TextStyle(
                        fontSize: 10.125,
                        fontWeight: FontWeight.w700,
                        color: context.adaptiveSlate900,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (createdRelative != null)
                      Text(
                        createdRelative,
                        style: TextStyle(
                          fontSize: 8.625,
                          color: context.adaptiveSlate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _buildPriorityIcon(ticket.priority),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ticket.title,
                style: TextStyle(
                  fontSize: 11.25,
                  fontWeight: FontWeight.w600,
                  color: headingColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (ticket.contactPhone != null && ticket.contactPhone!.trim().isNotEmpty) ...[
          Row(
            children: [
              Icon(LucideIcons.phone, size: 13, color: AppColors.slate500),
              const SizedBox(width: 5),
              Text(
                ticket.contactPhone!.trim(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.adaptiveSlate600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (statusPill != null) statusPill,
        if (actionButton != null) ...[
          const SizedBox(height: 12),
          actionButton,
        ],
      ],
    );
  }

  Widget _buildCompactContent({
    required BuildContext context,
    required WidgetRef ref,
    required Color headingColor,
    required AsyncValue<Map<String, dynamic>?> customerAsync,
    required bool canClaimTicket,
    required bool isMyTicket,
    required bool hasRibbon,
    required List<Map<String, dynamic>> agents,
  }) {
    final customer = customerAsync.maybeWhen(
      data: (data) => data == null ? null : Customer.fromJson(data),
      orElse: () => null,
    );
    final companyName = customer?.companyName.trim().isEmpty == true
        ? null
        : customer?.companyName;
    final referenceDateRaw = ticket.updatedAt ?? ticket.createdAt;
    final referenceDate =
        referenceDateRaw == null ? null : _toLocalTime(referenceDateRaw);
    final createdTimestamp = referenceDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(referenceDate)
        : null;
    final createdRelative =
        referenceDate != null
            ? timeago.format(
                referenceDate,
                clock: DateTime.now(),
              )
            : null;
    final actionButton = _buildActionButtons(
      context: context,
      ref: ref,
      canClaimTicket: canClaimTicket,
      isMyTicket: isMyTicket,

    );
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;
    final statusPill = _buildMinimalStatusPill(
      context: context,
      status: ticket.status,
      isUnassigned: isUnassigned,
      isMyTicket: isMyTicket,
      agents: agents,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyName != null || createdTimestamp != null) ...[
          Padding(
            padding: EdgeInsets.only(right: hasRibbon ? 88 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: companyName != null
                      ? Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: headingColor,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'No company linked',
                          style: TextStyle(
                            fontSize: 9.75,
                            fontWeight: FontWeight.w600,
                            color: context.adaptiveSlate500,
                          ),
                        ),
                ),
                if (createdTimestamp != null) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        createdTimestamp,
                        style: TextStyle(
                          fontSize: 9.375,
                          fontWeight: FontWeight.w700,
                          color: context.adaptiveSlate900,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      if (createdRelative != null)
                        Text(
                          createdRelative,
                          style: TextStyle(
                            fontSize: 8.25,
                            color: context.adaptiveSlate600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 3),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: _buildPriorityIcon(ticket.priority),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ticket.title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: headingColor,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (ticket.contactPhone != null && ticket.contactPhone!.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.phone, size: 10, color: AppColors.slate500),
              const SizedBox(width: 4),
              Text(
                ticket.contactPhone!.trim(),
                style: TextStyle(
                  fontSize: 9.75,
                  fontWeight: FontWeight.w500,
                  color: context.adaptiveSlate600,
                ),
              ),
            ],
          ),
        ],
        if (statusPill != null) ...[
          const SizedBox(height: 2),
          statusPill,
        ],
        if (actionButton != null) ...[
          const SizedBox(height: 4),
          actionButton,
        ],
      ],
    );
  }


  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: iconColor ?? AppColors.slate600),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.25,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildMinimalStatusPill({
    required BuildContext context,
    required String status,
    required bool isUnassigned,
    required bool isMyTicket,
    required List<Map<String, dynamic>> agents,
  }) {
    final normalized = status.trim().toLowerCase();

    if (_stageBilledStatuses.contains(normalized)) {
      return _buildInfoPill(
        icon: LucideIcons.receipt,
        label: 'Billed',
        iconColor: context.isDarkMode ? Colors.green.shade400 : AppColors.success,
        textColor: context.isDarkMode ? Colors.green.shade400 : AppColors.success,
        backgroundColor: context.isDarkMode ? Colors.green.shade400.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
      );
    }

    if (normalized == 'billraised') {
      return _buildInfoPill(
        icon: LucideIcons.fileText,
        label: 'Bill Raised',
        iconColor: context.isDarkMode ? Colors.red.shade200 : AppColors.warning,
        textColor: context.isDarkMode ? Colors.red.shade200 : AppColors.warning,
        backgroundColor: context.isDarkMode ? Colors.red.shade200.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
      );
    }

    if (normalized == 'resolved') {
      return _buildInfoPill(
        icon: LucideIcons.checkCircle,
        label: 'Resolved',
        iconColor: context.isDarkMode ? Colors.green.shade300 : AppColors.success,
        textColor: context.isDarkMode ? Colors.green.shade300 : AppColors.success,
        backgroundColor: context.isDarkMode ? Colors.green.shade300.withValues(alpha: 0.12) : AppColors.success.withValues(alpha: 0.12),
      );
    }

    if (!isUnassigned) {
      String label = 'Claimed';
      if (isMyTicket) {
        label = 'Claimed by you';
      } else {
        final assignedAgentId = ticket.assignedTo;
        if (assignedAgentId != null && assignedAgentId.isNotEmpty) {
          final agent = agents.where((a) => a['id'] == assignedAgentId).firstOrNull;
          if (agent != null) {
            label = agent['full_name'] ?? agent['username'] ?? 'Claimed';
          }
        }
      }
      return _buildInfoPill(
        icon: LucideIcons.userCheck,
        label: label,
        iconColor: context.isDarkMode ? Colors.blue.shade300 : AppColors.info,
        textColor: context.isDarkMode ? Colors.blue.shade300 : AppColors.info,
        backgroundColor: context.isDarkMode ? Colors.blue.shade300.withValues(alpha: 0.12) : AppColors.info.withValues(alpha: 0.12),
      );
    }

    return null;
  }

  Widget? _buildActionButtons({
    required BuildContext context,
    required WidgetRef ref,
    required bool canClaimTicket,
    required bool isMyTicket,
  }) {
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;

    final buttons = <Widget>[];

    if (canClaimTicket && isUnassigned) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 26,
          child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.userCheck, size: 12),
            label: const Text(
              'Claim ticket',
              style: TextStyle(fontSize: 9),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.info,
              side: BorderSide(color: AppColors.info.withValues(alpha: 0.6)),
            ),
            onPressed: () async {
              context.push('/ticket/${ticket.ticketId}');
            },
          ),
        ),
      );
    }

    // Simplified flow: no hold/resume buttons.

    if (buttons.isEmpty) {
      if (ticket.status == 'BillRaised') {
        return const SizedBox.shrink();
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i != buttons.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }



  Widget _buildPriorityIcon(String? priority) {
    Color color;
    IconData icon;

    final p = (priority ?? 'medium').toLowerCase();
    switch (p) {
      case 'urgent':
        color = AppColors.error;
        icon = LucideIcons.zap;
        break;
      case 'high':
        color = AppColors.warning;
        icon = LucideIcons.alertCircle;
        break;
      case 'medium':
        color = AppColors.info;
        icon = LucideIcons.flag;
        break;
      case 'low':
        color = AppColors.success;
        icon = LucideIcons.flag;
        break;
      default:
        color = AppColors.slate400;
        icon = LucideIcons.flag;
    }

    return Icon(icon, size: 14, color: color);
  }

}


class _UnclaimedGlassTag extends StatelessWidget {
  const _UnclaimedGlassTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7D1), Color(0xFFFFE495)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE495).withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(6, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Text(
            'Unclaimed',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7A4A00),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

