import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_colors.dart';

import '../../../features/tickets/presentation/providers/ticket_provider.dart';
import '../../../features/customers/presentation/providers/customer_provider.dart';
import '../../../features/dashboard/presentation/providers/app_settings_provider.dart';
import '../../network/connectivity_provider.dart';
import '../../../features/chat/presentation/providers/chat_provider.dart';
import '../../../features/chat/presentation/providers/custom_channel_provider.dart';
import '../../../features/chat/presentation/widgets/create_channel_dialog.dart';
import '../../../features/tickets/domain/entities/ticket.dart';
import '../../../features/chat/presentation/widgets/chat_toast_overlay.dart';
import '../../../features/productivity/presentation/widgets/add_reminder_dialog.dart';
import '../../../features/productivity/presentation/widgets/reminder_toast_overlay.dart';
import '../../../features/productivity/presentation/providers/reminder_provider.dart';
import '../../services/reminder_sound_service.dart';
import '../../services/chat_sound_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({super.key, required this.child, required this.currentPath});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  double _firstPaneWidth = 240;
  final double _minPaneWidth = 180;
  final double _maxPaneWidth = 400;
  bool _isTicketPaneOpen = true;
  bool _isMobileSidebarOpen = false;
  Timer? _lastSeenUpdateTimer;
  bool _isDisposed = false;
  bool _hasInitialized = false;
  ProviderSubscription? _chatListenerSubscription;
  ProviderSubscription? _aroundTallyListenerSubscription;
  ProviderContainer? _container;

  // Restricted agents check
  static const _allowedAroundTallyChannelIds = {
    'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
    'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
  };
  bool get _isRestrictedAgent {
    final currentUser = ref.read(authProvider);
    return _allowedAroundTallyChannelIds.contains(currentUser?.id ?? '');
  }

  @override
  void initState() {
    super.initState();
    // Listen once for the lifetime of the layout widget — never re-registers
    // on navigation rebuilds, so old messages never re-fire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed && !_hasInitialized) {
        _hasInitialized = true;
        _setupChatListener();
        _startLastSeenUpdates();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the container so async callbacks never look up an ancestor after deactivation
    _container = ProviderScope.containerOf(context);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _hasInitialized = false;
    _chatListenerSubscription?.close();
    _chatListenerSubscription = null;
    _aroundTallyListenerSubscription?.close();
    _aroundTallyListenerSubscription = null;
    _lastSeenUpdateTimer?.cancel();
    _lastSeenUpdateTimer = null;
    _container = null;
    super.dispose();
  }

  void _startLastSeenUpdates() {
    // Update last_seen immediately on start
    final container = _container;
    if (container != null && !_isDisposed) {
      final currentUser = container.read(authProvider);
      if (currentUser != null) {
        _updateLastSeen(currentUser.id);
      }
    }
    // Then update every 2 minutes while user is active
    _lastSeenUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      final c = _container;
      if (_isDisposed || c == null || _lastSeenUpdateTimer == null) {
        timer.cancel();
        return;
      }
      final currentUser = c.read(authProvider);
      if (currentUser != null) {
        _updateLastSeen(currentUser.id);
      }
      // Also refresh agents list to get updated last_seen from other users
      if (!_isDisposed && _container != null) {
        c.invalidate(agentsListProvider);
      }
    });
  }

  Future<void> _updateLastSeen(String agentId) async {
    if (_isDisposed || _container == null) return;
    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', agentId);
    } catch (e) {
      // Silently fail - this is non-critical
    }
  }

  void _setupChatListener() {
    final c = _container;
    if (c == null) return;
    // Use ProviderContainer.listen() directly — never touches the widget tree
    _chatListenerSubscription = c.listen(chatStreamProvider('support-chat'), (
      previous,
      next,
    ) {
      if (_isDisposed || _container == null) return;
      final myId = c.read(authProvider)?.id;
      if (myId == null) return;
      if (widget.currentPath.startsWith('/chat')) return;

      // Skip the very first emission (historical data load)
      if (previous == null) return;

      final prevMessages = previous.value ?? [];
      final nextMessages = next.value ?? [];
      if (nextMessages.length <= prevMessages.length) return;

      final prevIds = prevMessages.map((m) => m.id).toSet();

      // Only consider messages that are:
      //  1. Not in the previous snapshot (truly new this emission)
      //  2. Not sent by the current user
      //  3. Newer than the user's last-seen timestamp (not already read)
      final lastSeen = c.read(chatLastSeenProvider).value;
      final newMessages = nextMessages
          .where(
            (m) =>
                !prevIds.contains(m.id) &&
                m.senderId.trim().toLowerCase() != myId.trim().toLowerCase() &&
                (lastSeen == null || m.createdAt.toUtc().isAfter(lastSeen)),
          )
          .toList();

      if (newMessages.isNotEmpty) {
        final myFullName = c.read(authProvider)?.fullName ?? '';
        final hasMention = myFullName.isNotEmpty && 
            newMessages.any((m) => m.content.contains('@$myFullName') == true);
            
        if (hasMention) {
          ChatSoundService.playMentionPing();
        } else {
          ChatSoundService.playPing();
        }
        
        if (!_isDisposed && _container != null) {
          c.read(chatNewMessageEventProvider.notifier).notify(newMessages.last);
        }
      }
    });

    // All-AroundTally channel listener
    _aroundTallyListenerSubscription = c.listen(
      chatStreamProvider('all-aroundtally'),
      (previous, next) {
        if (_isDisposed || _container == null) return;
        final myId = c.read(authProvider)?.id;
        if (myId == null) return;
        if (widget.currentPath.startsWith('/channel/all-aroundtally')) return;

        // Skip the very first emission (historical data load)
        if (previous == null) return;

        final prevMessages = previous.value ?? [];
        final nextMessages = next.value ?? [];
        if (nextMessages.length <= prevMessages.length) return;

        final prevIds = prevMessages.map((m) => m.id).toSet();

        // Only consider messages that are:
        //  1. Not in the previous snapshot (truly new this emission)
        //  2. Not sent by the current user
        //  3. Newer than the user's last-seen timestamp (not already read)
        final lastSeen = c.read(allAroundTallyLastSeenProvider).value;
        final newMessages = nextMessages
            .where(
              (m) =>
                  !prevIds.contains(m.id) &&
                  m.senderId.trim().toLowerCase() !=
                      myId.trim().toLowerCase() &&
                  (lastSeen == null || m.createdAt.toUtc().isAfter(lastSeen)),
            )
            .toList();

        if (newMessages.isNotEmpty) {
          final myFullName = c.read(authProvider)?.fullName ?? '';
          final hasMention = myFullName.isNotEmpty && 
              newMessages.any((m) => m.content.contains('@$myFullName') == true);
              
          if (hasMention) {
            ChatSoundService.playMentionPing();
          } else {
            ChatSoundService.playPing();
          }
          
          if (!_isDisposed && _container != null) {
            c
                .read(allAroundTallyNewMessageEventProvider.notifier)
                .notify(newMessages.last);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep reminders provider alive for sound notifications
    ref.watch(remindersProvider);
    // Note: chatStreamProvider is already listened to in _setupChatListener,
    // no need to watch it here to avoid unnecessary rebuilds

    // Reminder sound
    ref.listen(lastTriggeredReminderProvider, (previous, next) {
      if (!mounted || _isDisposed) return;
      final prevIds = previous?.map((r) => r.id).toSet() ?? {};
      final nextIds = next.map((r) => r.id).toSet();
      if (nextIds.difference(prevIds).isNotEmpty) {
        ReminderSoundService.playBeep();
      }
    });

    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return ChatToastOverlay(
        currentPath: widget.currentPath,
        child: ReminderToastOverlay(
          child: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: _firstPaneWidth,
                  child: _LeftNav(currentPath: widget.currentPath),
                ),
                _ResizeHandle(
                  onDrag: (delta) {
                    setState(() {
                      _firstPaneWidth = (_firstPaneWidth + delta).clamp(
                        _minPaneWidth,
                        _maxPaneWidth,
                      );
                    });
                  },
                ),
                if (!_isRestrictedAgent && !widget.currentPath.startsWith('/sales-channel'))
                  _CollapsibleTicketPane(
                    currentPath: widget.currentPath,
                    isOpen: _isTicketPaneOpen,
                    onToggle: () =>
                        setState(() => _isTicketPaneOpen = !_isTicketPaneOpen),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      const _OfflineBanner(),
                      _TopNav(currentPath: widget.currentPath),
                      const Divider(height: 1, color: AppColors.border),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isChatRoute =
        widget.currentPath.startsWith('/chat') ||
        widget.currentPath.startsWith('/channel');
    final double sidebarWidth = 250.0;

    return ChatToastOverlay(
      currentPath: widget.currentPath,
      child: ReminderToastOverlay(
        child: Scaffold(
          body: Stack(
            children: [
              // Main Content
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const _OfflineBanner(),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
              // Mobile Chat Sidebar Overlay
              // Dark background overlay when sidebar is open
              if (_isMobileSidebarOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isMobileSidebarOpen = false),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.54),
                    ),
                  ),
                ),
              // The Sidebar itself
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                left: _isMobileSidebarOpen ? 0 : -sidebarWidth,
                width: sidebarWidth,
                child: _LeftNav(currentPath: widget.currentPath),
              ),
              // Toggle Button
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top:
                    MediaQuery.of(context).size.height / 2 -
                    24, // Vertically centered
                left: _isMobileSidebarOpen ? sidebarWidth : 0,
                child: GestureDetector(
                  onTap: () => setState(
                    () => _isMobileSidebarOpen = !_isMobileSidebarOpen,
                  ),
                  child: Container(
                    width: 24,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isMobileSidebarOpen
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(currentPath: widget.currentPath),
        ),
      ),
    );
  }
}

class _TopNav extends ConsumerWidget {
  final String currentPath;

  const _TopNav({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final advSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    // Alert counts not shown in nav anymore.

    final role = currentUser?.role ?? 'Support';
    final isSales = currentUser?.isSales == true;
    final isTeleCaller = currentUser?.isTeleCaller == true;
    final simplifyNav =
        currentUser?.isSupport == true ||
        currentUser?.isHR == true ||
        currentUser?.isProjectCoordinator == true ||
        currentUser?.isSupportHead == true ||
        isTeleCaller;

    // Restricted agents check
    const allowedAroundTallyChannelIds = {
      'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
      'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
    };
    final isRestrictedAgent = allowedAroundTallyChannelIds.contains(
      currentUser?.id ?? '',
    );

    // Feature flags (global enable/disable)
    final enableNotifications = appSettings == null
        ? true
        : (appSettings['enable_notifications'] ?? true);
    final enableGlobalSearch = appSettings == null
        ? true
        : (appSettings['enable_global_search'] ?? true);
    final enableReports = appSettings == null
        ? true
        : (appSettings['enable_reports'] ?? true);
    final enableDeals = appSettings == null
        ? true
        : (appSettings['enable_deals'] ?? true);

    // Per-role screen visibility (uses advanced settings if available)
    bool canSeeScreen(String screenId) {
      if (advSettings == null) return true;
      return advSettings.canRoleSeeScreen(role, screenId);
    }

    final showClaimTicketsLabel =
        currentUser?.isSupport == true ||
        currentUser?.isHR == true ||
        currentUser?.isProjectCoordinator == true ||
        currentUser?.isSupportHead == true;
    final showBillsAsDashboard = currentUser?.isAccountant == true;

    final canViewAmcReminder =
        !simplifyNav &&
        (currentUser?.isSupport == true ||
            currentUser?.isHR == true ||
            currentUser?.isProjectCoordinator == true ||
            currentUser?.isSupportHead == true ||
            currentUser?.isAgent == true);
    final canViewPastTickets =
        !simplifyNav &&
        (currentUser?.isSupport == true ||
            currentUser?.isHR == true ||
            currentUser?.isProjectCoordinator == true ||
            currentUser?.isSupportHead == true ||
            currentUser?.isAgent == true);
    final canViewBills =
        !simplifyNav ||
        currentUser?.isAdmin == true ||
        currentUser?.isAccountant == true;
    final canViewSalesOpportunity =
        currentUser?.isSupportHead == true && !simplifyNav;
    final canViewReports =
        enableReports &&
        !simplifyNav &&
        canSeeScreen('reports') &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);
    final canViewDeals =
        enableDeals &&
        !simplifyNav &&
        canSeeScreen('deals') &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);

    final unreadCount = ref.watch(chatUnreadCountProvider);

    // Main navigation items (left side)
    final isSalesChannel = currentPath.startsWith('/sales-channel');
    final mainNavItems = <Widget>[
      if (isSalesChannel) ...[
        _TopNavItem(
          label: 'Chat',
          icon: LucideIcons.messageCircle,
          path: '/sales-channel?tab=0',
          isActive:
              currentPath == '/sales-channel' ||
              currentPath.contains('/sales-channel') &&
                  (GoRouterState.of(context).uri.queryParameters['tab'] ??
                          '0') ==
                      '0',
        ),
        _TopNavItem(
          label: 'Sales',
          icon: LucideIcons.shoppingCart,
          path: '/sales-channel?tab=1',
          isActive:
              currentPath.contains('/sales-channel') &&
              (GoRouterState.of(context).uri.queryParameters['tab'] ?? '') ==
                  '1',
        ),
        _TopNavItem(
          label: 'Pipeline',
          icon: LucideIcons.layers,
          path: '/sales-channel?tab=2',
          isActive:
              currentPath.contains('/sales-channel') &&
              (GoRouterState.of(context).uri.queryParameters['tab'] ?? '') ==
                  '2',
        ),
      ] else ...[
        _TopNavItem(
          label: 'Chat',
          icon: LucideIcons.messageSquare,
          path: '/chat',
          isActive: currentPath.startsWith('/chat'),
          badgeCount: unreadCount,
        ),
        if (!isRestrictedAgent)
          _TopNavItem(
            label: showBillsAsDashboard
                ? 'Bills'
                : (isSales
                      ? 'Dashboard'
                      : (showClaimTicketsLabel ? 'Tickets' : 'Dashboard')),
            icon: showBillsAsDashboard
                ? LucideIcons.receipt
                : (showClaimTicketsLabel
                      ? LucideIcons.ticket
                      : LucideIcons.layoutDashboard),
            path: showBillsAsDashboard
                ? '/accountant'
                : (isSales
                      ? '/sales'
                      : (currentUser?.isSupport == true ||
                                currentUser?.isHR == true ||
                                currentUser?.isProjectCoordinator == true
                            ? '/support'
                            : '/')),
            isActive:
                currentPath == '/' ||
                currentPath == '/admin' ||
                currentPath == '/accountant' ||
                currentPath == '/sales' ||
                currentPath == '/support' ||
                (showClaimTicketsLabel &&
                    (currentPath.startsWith('/tickets') ||
                        currentPath.startsWith('/ticket'))),
          ),
        if (!isRestrictedAgent &&
            currentUser?.isAccountant != true &&
            currentUser?.isSupport != true &&
            currentUser?.isHR != true &&
            currentUser?.isProjectCoordinator != true &&
            currentUser?.isSupportHead != true)
          _TopNavItem(
            label: isSales
                ? 'My Tickets'
                : (isTeleCaller ? 'My Tickets' : 'Tickets'),
            icon: LucideIcons.ticket,
            path: '/tickets',
            isActive:
                currentPath.startsWith('/tickets') ||
                currentPath.startsWith('/ticket'),
          ),
        // Support Dashboard for Accountants
        if (!isRestrictedAgent && currentUser?.isAccountant == true)
          _TopNavItem(
            label: 'Support',
            icon: LucideIcons.headphones,
            path: '/support',
            isActive: currentPath == '/support',
          ),
      ],
    ];

    // Right side utility items (near profile)
    final useGroupedNav =
        currentUser?.isAdmin == true || currentUser?.isAccountant == true;

    final rightNavItems = <Widget>[
      if (enableNotifications)
        _TopNavButton(label: 'Alerts', icon: LucideIcons.bell, onTap: () {}),
      if (enableGlobalSearch)
        _TopNavButton(
          label: 'Search',
          icon: LucideIcons.search,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const _GlobalSearchDialog(),
            );
          },
        ),
      _TopNavButton(
        label: 'Reminder',
        icon: LucideIcons.alarmClock,
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const AddReminderDialog(),
          );
        },
      ),

      if (!useGroupedNav) ...[
        if (currentUser?.isTeleCaller != true && !isRestrictedAgent)
          _TopNavItem(
            label: 'Customers',
            icon: LucideIcons.users,
            path: '/customers',
            isActive:
                currentPath.startsWith('/customers') ||
                currentPath.startsWith('/customer'),
          ),
        if (canViewAmcReminder)
          _TopNavItem(
            label: 'AMC Reminder',
            icon: LucideIcons.calendarClock,
            path: '/amc-reminder',
            isActive: currentPath.startsWith('/amc-reminder'),
          ),
        if (!isRestrictedAgent &&
            currentUser?.isSoftwareDeveloper != true &&
            (canViewBills || currentUser?.isProjectCoordinator == true) &&
            !showBillsAsDashboard)
          _TopNavItem(
            label: 'Bills',
            icon: LucideIcons.receipt,
            path: '/bills',
            isActive: currentPath.startsWith('/bills'),
          ),
        if (!isRestrictedAgent && canViewPastTickets)
          _TopNavItem(
            label: 'Past Tickets',
            icon: LucideIcons.archive,
            path: '/past-tickets',
            isActive: currentPath == '/past-tickets',
          ),
        if (currentUser?.isAdmin == true || currentUser?.isAccountant == true)
          _TopNavItem(
            label: 'Revenue',
            icon: LucideIcons.indianRupee,
            path: '/revenue',
            isActive: currentPath.startsWith('/revenue'),
          ),
        if (canViewSalesOpportunity)
          _TopNavItem(
            label: 'Sales Opportunity',
            icon: LucideIcons.trendingUp,
            path: '/sales-opportunity',
            isActive: currentPath.startsWith('/sales-opportunity'),
          ),
        if (canViewReports)
          _TopNavItem(
            label: 'Reports',
            icon: LucideIcons.barChart,
            path: '/reports',
            isActive: currentPath.startsWith('/reports'),
          ),
        if (currentUser?.isAdmin == true ||
            currentUser?.isHR == true ||
            currentUser?.id == '326cf09e-ab94-4dd4-bc90-93c41d626b1d')
          _TopNavItem(
            label: 'User Management',
            icon: LucideIcons.users,
            path: '/users',
            isActive: currentPath.startsWith('/users'),
          ),
        if (canViewDeals)
          _TopNavItem(
            label: 'Deals',
            icon: LucideIcons.briefcase,
            path: '/deals',
            isActive: currentPath.startsWith('/deals'),
          ),
        if (currentUser?.isSales == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isAdmin == true)
          _TopNavItem(
            label: 'Leads',
            icon: LucideIcons.target,
            path: '/leads',
            isActive: currentPath.startsWith('/leads'),
          ),
        if (!(currentUser?.isSupport == true ||
                currentUser?.isHR == true ||
                currentUser?.isSupportHead == true) &&
            currentUser?.isTeleCaller != true &&
            currentUser?.isSoftwareDeveloper != true &&
            currentUser?.isDigitalMarketing != true)
          _TopNavItem(
            label: 'Proposals',
            icon: LucideIcons.fileText,
            path: '/proposal-generator',
            isActive: currentPath.startsWith('/proposal-generator'),
          ),
        if (currentUser?.isAdmin == true)
          _TopNavItem(
            label: 'Settings',
            icon: LucideIcons.settings,
            path: '/settings',
            isActive: currentPath.startsWith('/settings'),
          ),
      ] else ...[
        // Grouped Icon Menus for Admin and Accountant
        _TopNavHoverMenu(
          icon: LucideIcons.briefcase,
          tooltip: 'Sales',
          isParentActive:
              currentPath.startsWith('/leads') ||
              currentPath.startsWith('/deals') ||
              currentPath.startsWith('/proposal-generator') ||
              currentPath.startsWith('/customers') ||
              currentPath.startsWith('/customer'),
          items: [
            if (currentUser?.isSales == true ||
                currentUser?.isAccountant == true ||
                currentUser?.isAdmin == true)
              _DropdownItem(
                label: 'Leads',
                icon: LucideIcons.target,
                path: '/leads',
                isActive: currentPath.startsWith('/leads'),
              ),
            if (canViewDeals)
              _DropdownItem(
                label: 'Deals',
                icon: LucideIcons.briefcase,
                path: '/deals',
                isActive: currentPath.startsWith('/deals'),
              ),
            if (!(currentUser?.isSupport == true ||
                    currentUser?.isHR == true ||
                    currentUser?.isSupportHead == true) &&
                currentUser?.isSoftwareDeveloper != true &&
                currentUser?.isDigitalMarketing != true)
              _DropdownItem(
                label: 'Proposals',
                icon: LucideIcons.fileText,
                path: '/proposal-generator',
                isActive: currentPath.startsWith('/proposal-generator'),
              ),
            if (!isRestrictedAgent)
              _DropdownItem(
                label: 'Customers',
                icon: LucideIcons.users,
                path: '/customers',
                isActive:
                    currentPath.startsWith('/customers') ||
                    currentPath.startsWith('/customer'),
              ),
          ],
        ),

        _TopNavHoverMenu(
          icon: LucideIcons.indianRupee,
          tooltip: 'Finance',
          isParentActive:
              currentPath.startsWith('/bills') ||
              currentPath.startsWith('/revenue'),
          items: [
            if (currentUser?.isSoftwareDeveloper != true &&
                canViewBills &&
                !showBillsAsDashboard)
              _DropdownItem(
                label: 'Bills',
                icon: LucideIcons.receipt,
                path: '/bills',
                isActive: currentPath.startsWith('/bills'),
              ),
            if (currentUser?.isAdmin == true ||
                currentUser?.isAccountant == true)
              _DropdownItem(
                label: 'Revenue',
                icon: LucideIcons.indianRupee,
                path: '/revenue',
                isActive: currentPath.startsWith('/revenue'),
              ),
            if (currentUser?.isAccountant == true)
              _DropdownItem(
                label: 'Support',
                icon: LucideIcons.headphones,
                path: '/support',
                isActive: currentPath == '/support',
              ),
          ],
        ),

        if (canViewReports)
          _TopNavHoverMenu(
            icon: LucideIcons.barChart,
            tooltip: 'Analytics',
            isParentActive: currentPath.startsWith('/reports'),
            onDirectTap: () => context.go('/reports'),
          ),

        _TopNavHoverMenu(
          icon: LucideIcons.settings,
          tooltip: 'Administration',
          isParentActive:
              currentPath.startsWith('/users') ||
              currentPath.startsWith('/settings'),
          items: [
            if (currentUser?.isAdmin == true || currentUser?.isHR == true)
              _DropdownItem(
                label: 'User Management',
                icon: LucideIcons.users,
                path: '/users',
                isActive: currentPath.startsWith('/users'),
              ),
            if (currentUser?.isAdmin == true)
              _DropdownItem(
                label: 'Settings',
                icon: LucideIcons.settings,
                path: '/settings',
                isActive: currentPath.startsWith('/settings'),
              ),
          ],
        ),
      ],
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primaryDark, AppColors.slate900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.checkSquare,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'TallyCare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0x1AFFFFFF)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: mainNavItems),
            ),
          ),

          // Right side navigation items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: rightNavItems),
          ),

          // Refresh button - invalidate providers instead of full page reload
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(
                  LucideIcons.refreshCw,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () {
                  // Invalidate all data providers to refresh without page reload
                  ref.invalidate(rawTicketsStreamProvider);
                  ref.invalidate(ticketStatsProvider);
                  ref.invalidate(customersListProvider);
                  ref.invalidate(agentsListProvider);
                  ref.invalidate(chatStreamProvider('support-chat'));
                  ref.invalidate(dmConversationsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data refreshed'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                tooltip: 'Refresh Data',
                padding: const EdgeInsets.all(12),
              );
            },
          ),

          const SizedBox(width: 56, child: _UserProfile()),
        ],
      ),
    );
  }
}

class _GlobalSearchDialog extends ConsumerStatefulWidget {
  const _GlobalSearchDialog();

  @override
  ConsumerState<_GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<_GlobalSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 640,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Global Search',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tickets or customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ticketsAsync.when(
                  data: (tickets) {
                    return customersAsync.when(
                      data: (customers) {
                        final q = _query.toLowerCase();

                        final ticketResults = q.isEmpty
                            ? <dynamic>[]
                            : tickets
                                  .where((t) {
                                    final title = t.title.toLowerCase();
                                    final id = t.ticketId.toLowerCase();
                                    final desc = (t.description ?? '')
                                        .toString()
                                        .toLowerCase();
                                    return title.contains(q) ||
                                        id.contains(q) ||
                                        desc.contains(q);
                                  })
                                  .take(10)
                                  .toList();

                        final customerResults = q.isEmpty
                            ? <dynamic>[]
                            : customers
                                  .where((c) {
                                    final name = c.companyName.toLowerCase();
                                    final apiKey = c.apiKey.toLowerCase();
                                    return name.contains(q) ||
                                        apiKey.contains(q);
                                  })
                                  .take(10)
                                  .toList();

                        if (ticketResults.isEmpty && customerResults.isEmpty) {
                          return const Center(
                            child: Text(
                              'Type to search tickets or customers',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.slate500,
                              ),
                            ),
                          );
                        }

                        return ListView(
                          children: [
                            if (ticketResults.isNotEmpty) ...[
                              const Text(
                                'Tickets',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ticketResults.map((t) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    LucideIcons.ticket,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(
                                    t.title ?? 'Ticket',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'ID: ${t.ticketId}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.push('/ticket/${t.ticketId}');
                                  },
                                );
                              }),
                              const SizedBox(height: 12),
                            ],
                            if (customerResults.isNotEmpty) ...[
                              const Text(
                                'Customers',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...customerResults.map((c) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    LucideIcons.users,
                                    size: 18,
                                    color: AppColors.slate700,
                                  ),
                                  title: Text(
                                    c.companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    c.apiKey,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.push('/customer/${c.id}');
                                  },
                                );
                              }),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error loading customers: $err',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading tickets: $err',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
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
}

class _TopNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final String path;
  final bool isActive;
  final int badgeCount;

  const _TopNavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.isActive,
    this.badgeCount = 0,
  });

  @override
  State<_TopNavItem> createState() => _TopNavItemState();
}

class _TopNavItemState extends State<_TopNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withValues(alpha: 0.72);
    final activeColor = AppColors.primaryLight;
    final itemColor = widget.isActive
        ? activeColor.withValues(alpha: 0.16)
        : (_isHovered
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(widget.path),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(8),
                border: widget.isActive
                    ? Border.all(
                        color: activeColor.withValues(alpha: 0.32),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 17,
                    color: widget.isActive ? activeColor : inactiveColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.isActive ? Colors.white : inactiveColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.badgeCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        widget.badgeCount > 9
                            ? '9+'
                            : widget.badgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TopNavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItem {
  final String label;
  final IconData icon;
  final String path;
  final bool isActive;
  final VoidCallback? onTap;

  _DropdownItem({
    required this.label,
    required this.icon,
    this.path = '',
    this.isActive = false,
    this.onTap,
  });
}

class _TopNavHoverMenu extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final List<_DropdownItem> items;
  final bool isParentActive;
  final VoidCallback? onDirectTap;

  const _TopNavHoverMenu({
    super.key,
    required this.icon,
    required this.tooltip,
    this.items = const [],
    this.isParentActive = false,
    this.onDirectTap,
  });

  @override
  State<_TopNavHoverMenu> createState() => _TopNavHoverMenuState();
}

class _TopNavHoverMenuState extends State<_TopNavHoverMenu>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isMenuHovered = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _key = GlobalKey();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _checkAndHide() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isHovered && !_isMenuHovered && mounted) {
        _animController.reverse().then((_) {
          if (mounted && !_isHovered && !_isMenuHovered) {
            _removeOverlay();
          }
        });
      }
    });
  }

  void _showOverlay() {
    if (widget.items.isEmpty) return;
    if (_overlayEntry != null) return;

    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: offset.dx,
          top: offset.dy + size.height,
          child: MouseRegion(
            onEnter: (_) {
              _isMenuHovered = true;
            },
            onExit: (_) {
              _isMenuHovered = false;
              _checkAndHide();
            },
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.only(top: 8), // Gap bridge
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.slate800,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    width: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.items.map((item) {
                        return InkWell(
                          onTap: () {
                            _removeOverlay();
                            if (item.onTap != null) {
                              item.onTap!();
                            } else if (item.path.isNotEmpty) {
                              context.go(item.path);
                            }
                          },
                          hoverColor: Colors.white.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 16,
                                  color: item.isActive
                                      ? AppColors.primaryLight
                                      : Colors.white.withValues(alpha: 0.72),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: item.isActive
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.8),
                                    fontWeight: item.isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.onDirectTap == null)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: MouseRegion(
        onEnter: (_) {
          _isHovered = true;
          if (widget.items.isNotEmpty) {
            _showOverlay();
          }
        },
        onExit: (_) {
          _isHovered = false;
          if (widget.items.isNotEmpty) {
            _checkAndHide();
          }
        },
        child: InkWell(
          key: _key,
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (widget.items.isEmpty && widget.onDirectTap != null) {
              widget.onDirectTap!();
            }
          },
          child: Tooltip(
            message: widget.tooltip,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isParentActive
                    ? AppColors.primaryLight.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: widget.isParentActive
                    ? AppColors.primaryLight
                    : Colors.white.withValues(alpha: 0.72),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final String path;
  final bool isActive;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.isActive,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withValues(alpha: 0.6);
    final hoverColor = Colors.white.withValues(alpha: 0.08);
    final activeColor = AppColors.primaryLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(widget.path),
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? activeColor.withValues(alpha: 0.15)
                    : (_isHovered ? hoverColor : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: widget.isActive
                    ? Border.all(
                        color: activeColor.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          size: 18,
                          color: widget.isActive ? activeColor : inactiveColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: widget.isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: widget.isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
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
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final String currentPath;

  const _BottomNav({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final enableReports = appSettings == null
        ? true
        : (appSettings['enable_reports'] ?? true);
    final enableDeals = appSettings == null
        ? true
        : (appSettings['enable_deals'] ?? true);

    final isAccountant = currentUser?.isAccountant == true;
    final isAdmin = currentUser?.isAdmin == true;
    final isSupportHead = currentUser?.isSupportHead == true;
    final simplifyNav =
        currentUser?.isSupport == true ||
        currentUser?.isHR == true ||
        currentUser?.isProjectCoordinator == true ||
        currentUser?.isSupportHead == true;
    final renameDashboard = simplifyNav;
    final canSeeRevenue = isAdmin || isAccountant;
    final canSeeReports =
        (!simplifyNav) && (isAdmin || isSupportHead || isAccountant);
    final showReportsDestination = enableReports && canSeeReports;

    // Restricted agents check
    const allowedAroundTallyChannelIds = {
      'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
      'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
    };
    final isRestrictedAgent = allowedAroundTallyChannelIds.contains(
      currentUser?.id ?? '',
    );

    // Unified bottom navigation structure
    final destinations = <NavigationDestination>[];
    final navRoutes = <String>[];

    // Dashboard - hidden from restricted agents and support-only users
    final isSupportOnly =
        currentUser?.isSupport == true ||
        currentUser?.isHR == true ||
        currentUser?.isProjectCoordinator == true;
    if (!isRestrictedAgent && !isSupportOnly) {
      destinations.add(
        NavigationDestination(
          icon: Icon(
            isAccountant ? LucideIcons.receipt : LucideIcons.layoutDashboard,
          ),
          selectedIcon: Icon(
            isAccountant ? LucideIcons.receipt : LucideIcons.layoutDashboard,
            color: AppColors.primary,
          ),
          label: isAccountant
              ? 'Bills'
              : (renameDashboard ? 'Claim Tickets' : 'Dashboard'),
        ),
      );
      navRoutes.add('/');
    }

    // Support Dashboard for Accountants
    if (isAccountant && !isRestrictedAgent) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.headphones),
          selectedIcon: Icon(LucideIcons.headphones, color: AppColors.primary),
          label: 'Support',
        ),
      );
      navRoutes.add('/support');
    }

    // Tickets - hidden from restricted agents
    if (!isAccountant && !isRestrictedAgent) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.ticket),
          selectedIcon: Icon(LucideIcons.ticket, color: AppColors.primary),
          label: 'Tickets',
        ),
      );
      navRoutes.add('/tickets');
    }

    // Chat
    final rawChatUnread = ref.watch(chatUnreadCountProvider);
    final chatUnread = currentPath.startsWith('/chat') ? 0 : rawChatUnread;
    destinations.add(
      NavigationDestination(
        icon: chatUnread > 0
            ? Badge(
                label: Text(chatUnread > 9 ? '9+' : chatUnread.toString()),
                backgroundColor: AppColors.error,
                child: const Icon(LucideIcons.messageSquare),
              )
            : const Icon(LucideIcons.messageSquare),
        selectedIcon: chatUnread > 0
            ? Badge(
                label: Text(chatUnread > 9 ? '9+' : chatUnread.toString()),
                backgroundColor: AppColors.error,
                child: const Icon(
                  LucideIcons.messageSquare,
                  color: AppColors.primary,
                ),
              )
            : const Icon(LucideIcons.messageSquare, color: AppColors.primary),
        label: 'Chat',
      ),
    );
    navRoutes.add('/chat');

    // Search
    destinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.search),
        selectedIcon: Icon(LucideIcons.search, color: AppColors.primary),
        label: 'Search',
      ),
    );
    navRoutes.add('__search__');

    // Proposals - hidden from restricted agents and Digital Marketing Executive
    if (!(currentUser?.isSupport == true ||
            currentUser?.isHR == true ||
            currentUser?.isSupportHead == true) &&
        currentUser?.isSoftwareDeveloper != true &&
        currentUser?.isDigitalMarketing != true &&
        !isRestrictedAgent) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.fileText),
          selectedIcon: Icon(LucideIcons.fileText, color: AppColors.primary),
          label: 'Proposals',
        ),
      );
      navRoutes.add('/proposal-generator');
    }

    // Ticket Alerts moved to More menu

    // Leads - for sales, accountant & admin
    if (currentUser?.isSales == true ||
        currentUser?.isAccountant == true ||
        currentUser?.isAdmin == true) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.target),
          selectedIcon: Icon(LucideIcons.target, color: AppColors.primary),
          label: 'Leads',
        ),
      );
      navRoutes.add('/leads');
    }

    // Revenue - only for admin/accountant
    if (canSeeRevenue) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.indianRupee),
          selectedIcon: Icon(LucideIcons.indianRupee, color: AppColors.primary),
          label: 'Revenue',
        ),
      );
      navRoutes.add('/revenue');
    }

    // Deals
    final canViewDeals = enableDeals &&
        !simplifyNav &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);

    if (canViewDeals) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.briefcase),
          selectedIcon: Icon(LucideIcons.briefcase, color: AppColors.primary),
          label: 'Deals',
        ),
      );
      navRoutes.add('/deals');
    }

    // Reports - shown for admins, moderators, accountants when enabled
    if (showReportsDestination) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.barChart3),
          selectedIcon: Icon(LucideIcons.barChart3, color: AppColors.primary),
          label: 'Reports',
        ),
      );
      navRoutes.add('/reports');
    }

    // Customers - hidden from restricted agents
    if (!isRestrictedAgent) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.users),
          selectedIcon: Icon(LucideIcons.users, color: AppColors.primary),
          label: 'Customers',
        ),
      );
      navRoutes.add('/customers');
    }

    // Profile - always shown
    destinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.user),
        selectedIcon: Icon(LucideIcons.user, color: AppColors.primary),
        label: 'Profile',
      ),
    );
    navRoutes.add('/profile');

    // Mobile bottom nav: cap at 5 visible items, overflow goes to a "More" menu
    final visibleDestinations = <NavigationDestination>[];
    final visibleRoutes = <String>[];
    final moreDestinations = <NavigationDestination>[];
    final moreRoutes = <String>[];

    for (int i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      final route = navRoutes[i];

      if (route == '/tickets' || route == '/chat' || route == '__search__') {
        visibleDestinations.add(dest);
        visibleRoutes.add(route);
      } else {
        moreDestinations.add(dest);
        moreRoutes.add(route);
      }
    }

    // Always add Alerts to More menu
    if (!isAccountant && !isRestrictedAgent) {
      moreDestinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.alertTriangle),
          selectedIcon: Icon(
            LucideIcons.alertTriangle,
            color: AppColors.primary,
          ),
          label: 'Alerts',
        ),
      );
      moreRoutes.add('/alerts/unclaimed');
    }

    // Always add Reminder to More menu
    moreDestinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.alarmClock),
        selectedIcon: Icon(LucideIcons.alarmClock, color: AppColors.primary),
        label: 'Reminder',
      ),
    );
    moreRoutes.add('__reminder__');

    // Add User Management to More menu for Admin or HR
    if (isAdmin || currentUser?.isHR == true) {
      moreDestinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.userCog),
          selectedIcon: Icon(LucideIcons.userCog, color: AppColors.primary),
          label: 'User Management',
        ),
      );
      moreRoutes.add('/users');
    }

    // Add 'More' button to visible items
    visibleDestinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.moreHorizontal),
        selectedIcon: Icon(
          LucideIcons.moreHorizontal,
          color: AppColors.primary,
        ),
        label: 'More',
      ),
    );
    visibleRoutes.add('__more__');

    // If the current route is in the overflow menu, highlight More
    int selectedIndex = _getSelectedIndex(
      currentPath,
      visibleRoutes,
      isAccountant,
    );
    if (moreRoutes.isNotEmpty) {
      final overflowIndex = _getSelectedIndex(
        currentPath,
        moreRoutes,
        isAccountant,
      );
      if (overflowIndex >= 0 && overflowIndex < moreRoutes.length) {
        selectedIndex = visibleDestinations.length - 1;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 52,
        onDestinationSelected: (index) {
          if (index == visibleDestinations.length - 1 &&
              moreDestinations.isNotEmpty) {
            _showMoreMenu(context, moreDestinations, moreRoutes, currentPath);
          } else if (visibleRoutes[index] == '__search__') {
            showDialog(
              context: context,
              builder: (_) => const _GlobalSearchDialog(),
            );
          } else {
            _handleNavigation(context, index, visibleRoutes);
          }
        },
        destinations: visibleDestinations,
      ),
    );
  }

  void _showMoreMenu(
    BuildContext context,
    List<NavigationDestination> destinations,
    List<String> routes,
    String currentPath,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'More',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              ...List.generate(destinations.length, (index) {
                final dest = destinations[index];
                final route = routes[index];
                final isActive =
                    currentPath == route ||
                    (route != '/' && currentPath.startsWith(route));
                final icon = isActive
                    ? (dest.selectedIcon ?? dest.icon)
                    : dest.icon;
                return ListTile(
                  leading: IconTheme(
                    data: IconThemeData(
                      color: isActive ? AppColors.primary : AppColors.slate500,
                    ),
                    child: icon,
                  ),
                  title: Text(
                    dest.label,
                    style: TextStyle(
                      color: isActive ? AppColors.primary : AppColors.slate900,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (route == '__search__') {
                      showDialog(
                        context: context,
                        builder: (_) => const _GlobalSearchDialog(),
                      );
                    } else if (route == '__reminder__') {
                      showDialog(
                        context: context,
                        builder: (_) => const AddReminderDialog(),
                      );
                    } else {
                      context.go(route);
                    }
                  },
                );
              }),
            ],
          ),
          ),
        );
      },
    );
  }

  int _getSelectedIndex(
    String current,
    List<String> routes,
    bool isAccountant,
  ) {
    // Exact matches first
    final exactIndex = routes.indexOf(current);
    if (exactIndex != -1) return exactIndex;

    // Special cases
    if (current.startsWith('/ticket')) {
      final ticketIndex = routes.indexOf('/tickets');
      if (ticketIndex != -1) return ticketIndex;
    }
    if (current.startsWith('/customer')) {
      final customerIndex = routes.indexOf('/customers');
      if (customerIndex != -1) return customerIndex;
    }
    // Handle alerts routes
    if (current.startsWith('/alerts/')) {
      final alertsIndex = routes.indexOf('/alerts/unclaimed');
      if (alertsIndex != -1) return alertsIndex;
    }
    // Admin, Accountant, Support dashboards map to '/'
    if (current == '/admin' ||
        current == '/support' ||
        (isAccountant && current == '/accountant') ||
        current == '/sales') {
      return 0; // Home is always 0
    }

    // Fallback: prefix matching
    // Sort routes by length desc to match longest prefix first (e.g. /users vs /)
    final sortedIndices = List.generate(routes.length, (i) => i)
      ..sort((a, b) => routes[b].length.compareTo(routes[a].length));

    for (final index in sortedIndices) {
      final route = routes[index];
      if (route == '/') continue; // Skip root for prefix matching
      if (current.startsWith(route)) {
        return index;
      }
    }

    return 0; // Default to home
  }

  void _handleNavigation(BuildContext context, int index, List<String> routes) {
    print('DEBUG: Navigation pressed - index: $index, routes: $routes');
    if (index >= 0 && index < routes.length) {
      final route = routes[index];
      print('DEBUG: Navigating to: $route');
      context.go(route);
    } else {
      print('DEBUG: Invalid navigation index: $index');
    }
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (status) {
        final isOffline = status == ConnectivityResult.none;

        if (!isOffline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: const Text(
            'You are offline. Some features may be unavailable.',
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UserProfile extends ConsumerWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    return Tooltip(
      message:
          '${currentUser?.fullName ?? 'User'} (${currentUser?.role ?? 'Role'})',
      child: IconButton(
        icon: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          backgroundImage: currentUser?.avatarUrl != null
              ? NetworkImage(currentUser!.avatarUrl!)
              : null,
          child: currentUser?.avatarUrl == null
              ? Text(
                  currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
        onPressed: () => context.go('/profile'),
        tooltip:
            '${currentUser?.fullName ?? 'User'} (${currentUser?.role ?? 'Role'})',
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}

// -- Left Navigation (Empty for Support Chat) -------------------------------

class _LeftNav extends ConsumerWidget {
  final String currentPath;

  const _LeftNav({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.slate900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Channels and DMs section
            Expanded(child: _ChannelsList(currentPath: currentPath)),
          ],
        ),
      ),
    );
  }
}

// -- Resize Handle Widget ----------------------------------------------------

class _ResizeHandle extends StatefulWidget {
  final Function(double) onDrag;

  const _ResizeHandle({required this.onDrag});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _isHovering = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _isDragging = true),
        onHorizontalDragUpdate: (details) {
          widget.onDrag(details.delta.dx);
        },
        onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
        child: Container(
          width: 4,
          decoration: BoxDecoration(
            color: _isHovering || _isDragging
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            border: Border(
              right: BorderSide(
                color: _isHovering || _isDragging
                    ? AppColors.primary
                    : AppColors.border,
                width: _isHovering || _isDragging ? 2 : 1,
              ),
            ),
          ),
          child: _isHovering || _isDragging
              ? Center(
                  child: Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// -- Collapsible Ticket Pane -------------------------------------------------

class _CollapsibleTicketPane extends ConsumerWidget {
  final String currentPath;
  final bool isOpen;
  final VoidCallback onToggle;

  const _CollapsibleTicketPane({
    required this.currentPath,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    final tickets = ticketsAsync.value ?? [];
    final now = DateTime.now();
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    final recentTickets = tickets
        .where((t) => t.createdAt != null && t.createdAt!.isAfter(twoDaysAgo))
        .toList();

    // ignore: unused_local_variable
    final unclaimedCount = recentTickets
        .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
        .length;
    // ignore: unused_local_variable
    final claimedCount = recentTickets
        .where((t) => t.assignedTo != null && t.assignedTo!.isNotEmpty)
        .where(
          (t) =>
              t.status != 'Resolved' &&
              t.status != 'Closed' &&
              t.status != 'BillRaised' &&
              t.status != 'BillProcessed',
        )
        .length;
    // ignore: unused_local_variable
    final resolvedCount = recentTickets
        .where(
          (t) =>
              t.status == 'Resolved' ||
              t.status == 'Closed' ||
              t.status == 'BillRaised' ||
              t.status == 'BillProcessed',
        )
        .length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsed arrow strip — only visible when pane is closed
        if (!isOpen)
          Container(
            width: 24,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryDark, AppColors.slate900],
              ),
              border: Border(
                right: BorderSide(color: Color(0x1AFFFFFF), width: 1),
              ),
            ),
            child: Center(
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    LucideIcons.chevronsRight,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        // Expanded pane — animated
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: isOpen ? 240 : 0,
          child: isOpen
              ? _SecondLeftNav(currentPath: currentPath, onCollapse: onToggle)
              : const SizedBox.shrink(),
        ),
        if (isOpen) const VerticalDivider(width: 1, color: AppColors.border),
      ],
    );
  }
}

// -- Second Left Navigation (Additional Pane) -------------------------------

class _SecondLeftNav extends ConsumerWidget {
  final String currentPath;
  final VoidCallback? onCollapse;

  const _SecondLeftNav({required this.currentPath, this.onCollapse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSalesChannel = currentPath.startsWith('/sales-channel');
    final sectionTitle = isSalesChannel ? 'Recent Sales' : 'Recent Tickets';

    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.slate900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Recent tickets/sales section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onCollapse != null)
                  InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        LucideIcons.chevronsLeft,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x1AFFFFFF)),
          Expanded(
            child: isSalesChannel
                ? const _RecentSalesPlaceholder()
                : _RecentTicketsList(),
          ),
        ],
      ),
    );
  }
}

class _ChannelsList extends ConsumerStatefulWidget {
  final String currentPath;

  const _ChannelsList({required this.currentPath});

  @override
  ConsumerState<_ChannelsList> createState() => _ChannelsListState();
}

class _ChannelsListState extends ConsumerState<_ChannelsList> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = widget.currentPath;
    final isChatActive = currentPath.startsWith('/chat');
    final agentsAsync = ref.watch(agentsListProvider);
    final conversationsAsync = ref.watch(dmConversationsProvider);
    final currentUser = ref.watch(authProvider);
    final customChannelsAsync = ref.watch(customChannelsProvider);

    const allowedSalesChannelIds = {
      '0a5aeeb8-9544-4dc8-920f-e26c192b0dd3',
      '1f4d7758-12ba-43eb-9e47-cc0c95b740b8',
      '14db36db-0cb9-44ef-8032-d9610b3bc797',
      'b77b3738-4dfc-4515-a1fd-d6fb170423f4',
      'd8aa6435-9e02-4bab-9acc-ae1f5f3d6a1c',
      '5a06a8df-97f1-4dbf-bc13-9724a3c779c1',
    };
    const allowedAroundTallyChannelIds = {
      'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
      'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
    };
    final isRestrictedAgent = allowedAroundTallyChannelIds.contains(
      currentUser?.id ?? '',
    );
    final canAccessSalesChannel =
        allowedSalesChannelIds.contains(currentUser?.id ?? '') &&
        !isRestrictedAgent;
    final canAccessDealsTracker =
        currentUser?.id == '0a5aeeb8-9544-4dc8-920f-e26c192b0dd3';
    final restrictedFromAroundAi = {
      'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
      'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
    }.contains(currentUser?.id ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Companies Header - hidden from restricted agents
        if (!isRestrictedAgent)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.building2,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Companies',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        // AroundTally Company - hidden from restricted agents
        if (!isRestrictedAgent)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/company/aroundtally'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentPath.startsWith('/company/aroundtally')
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.building2,
                      size: 16,
                      color: currentPath.startsWith('/company/aroundtally')
                          ? Colors.white
                          : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AroundTally',
                      style: TextStyle(
                        color: currentPath.startsWith('/company/aroundtally')
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight:
                            currentPath.startsWith('/company/aroundtally')
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // AroundAi Company - hidden from restricted agents
        if (!isRestrictedAgent)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: restrictedFromAroundAi
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You do not have access to AroundAi'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  : () => context.go('/company/aroundai'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentPath.startsWith('/company/aroundai')
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.building2,
                      size: 16,
                      color: currentPath.startsWith('/company/aroundai')
                          ? Colors.white
                          : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AroundAi',
                      style: TextStyle(
                        color: currentPath.startsWith('/company/aroundai')
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: currentPath.startsWith('/company/aroundai')
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (restrictedFromAroundAi) ...[
                      const SizedBox(width: 6),
                      Icon(LucideIcons.lock, size: 12, color: Colors.white54),
                    ],
                  ],
                ),
              ),
            ),
          ),

        // Channels Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(LucideIcons.hash, size: 14, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Channels',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CreateChannelDialog(),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Dynamic Channels
        if (customChannelsAsync.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Error: ${customChannelsAsync.error}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        if (customChannelsAsync.hasValue) ...[
          for (final channel in customChannelsAsync.value!)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/c/${channel.id}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentPath.startsWith('/c/${channel.id}')
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        channel.isPrivate ? LucideIcons.lock : LucideIcons.hash,
                        size: 16,
                        color: currentPath.startsWith('/c/${channel.id}') ? Colors.white : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          channel.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: currentPath.startsWith('/c/${channel.id}') ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: currentPath.startsWith('/c/${channel.id}')
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],

        // Support Chat Channel
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/chat'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isChatActive
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.hash,
                    size: 16,
                    color: isChatActive ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'support-chat',
                    style: TextStyle(
                      color: isChatActive ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: isChatActive
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Sales Channel
        if (canAccessSalesChannel)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/sales-channel'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentPath.startsWith('/sales-channel')
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hash,
                      size: 16,
                      color: currentPath.startsWith('/sales-channel')
                          ? Colors.white
                          : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'sales',
                      style: TextStyle(
                        color: currentPath.startsWith('/sales-channel')
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: currentPath.startsWith('/sales-channel')
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Deals Tracker Channel
        if (canAccessDealsTracker)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/deals-tracker'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: currentPath.startsWith('/deals-tracker')
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hash,
                      size: 16,
                      color: currentPath.startsWith('/deals-tracker')
                          ? Colors.white
                          : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'deals-tracker',
                      style: TextStyle(
                        color: currentPath.startsWith('/deals-tracker')
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 13,
                        fontWeight: currentPath.startsWith('/deals-tracker')
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // All-AroundTally Channel - accessible to all users
        Consumer(
          builder: (context, ref, child) {
            // Keep the stream alive so unread count updates even when not on the page
            ref.watch(chatStreamProvider(kAllAroundTallyChannel));
            final aroundTallyUnread = ref.watch(
              allAroundTallyUnreadCountProvider,
            );
            final isOnChannel = currentPath.startsWith(
              '/channel/all-aroundtally',
            );
            final displayUnread = isOnChannel ? 0 : aroundTallyUnread;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/channel/all-aroundtally'),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOnChannel
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.hash,
                        size: 16,
                        color: isOnChannel ? Colors.white : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'all-aroundtally',
                        style: TextStyle(
                          color: (isOnChannel || displayUnread > 0)
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: (isOnChannel || displayUnread > 0)
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (currentUser?.isTeleCaller != true || isRestrictedAgent || currentUser?.id == 'f398fe3a-ea5f-4f98-9720-b3e32e798a63') ...[
          const SizedBox(height: 16),
          // Direct Messages Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.messagesSquare,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Direct messages',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Refresh button
                InkWell(
                  onTap: () {
                    ref.invalidate(agentsListProvider);
                    ref.invalidate(dmConversationsProvider);
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.refresh, size: 14, color: Colors.white54),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Agents List
          Expanded(
            child: agentsAsync.when(
              data: (agents) {
                return conversationsAsync.when(
                  data: (conversations) {
                    // Filter out specific agents
                    final hiddenAgentIds = const {
                      '1f4d7758-12ba-43eb-9e47-cc0c95b740b8',
                      '2d58eb0a-916a-4cb6-9245-b5b124caa0a3',
                    };
                    final filteredAgents = agents.where((a) {
                      final id = a['id']?.toString() ?? '';
                      return !hiddenAgentIds.contains(id);
                    }).toList();

                    // Sort agents: own chat first, then unread, then alphabetical
                    final sortedAgents = List.from(filteredAgents)
                      ..sort((a, b) {
                        final agentAId = a['id']?.toString() ?? '';
                        final agentBId = b['id']?.toString() ?? '';

                        // Own chat pinned to the top
                        if (currentUser != null) {
                          if (agentAId == currentUser.id &&
                              agentBId != currentUser.id)
                            return -1;
                          if (agentBId == currentUser.id &&
                              agentAId != currentUser.id)
                            return 1;
                        }

                        // Agents with unread messages come before agents without
                        final unreadA = ref.watch(
                          dmUnreadCountProvider(agentAId),
                        );
                        final unreadB = ref.watch(
                          dmUnreadCountProvider(agentBId),
                        );
                        if (unreadA > 0 && unreadB == 0) return -1;
                        if (unreadB > 0 && unreadA == 0) return 1;

                        // Otherwise alphabetical
                        final nameA = (a['full_name'] ?? a['username'] ?? '')
                            .toString()
                            .toLowerCase();
                        final nameB = (b['full_name'] ?? b['username'] ?? '')
                            .toString()
                            .toLowerCase();
                        return nameA.compareTo(nameB);
                      });

                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: sortedAgents.length,
                      itemBuilder: (context, index) {
                        final agent = sortedAgents[index];
                        final agentId = agent['id']?.toString() ?? '';
                        final currentUser = ref.watch(authProvider);
                        final isCurrentUser = currentUser?.id == agentId;
                        final name = isCurrentUser
                            ? 'YOU'
                            : (agent['full_name'] ?? 'Unknown');
                        final unreadCount = ref.watch(
                          dmUnreadCountProvider(agentId),
                        );

                        // Determine online status based on last_seen timestamp
                        final lastSeen = agent['last_seen'] != null
                            ? DateTime.tryParse(agent['last_seen'].toString())
                            : null;
                        final now = DateTime.now();

                        // Online: seen within last 5 minutes
                        final isOnline =
                            lastSeen != null &&
                            now.difference(lastSeen).inMinutes < 5;

                        // Away: seen within last 30 minutes but not online
                        final isAway =
                            lastSeen != null &&
                            !isOnline &&
                            now.difference(lastSeen).inMinutes < 30;

                        // Generate a distinct color based on index
                        final List<Color> avatarColors = [
                          Colors.red.shade400,
                          Colors.blue.shade400,
                          Colors.green.shade500,
                          Colors.orange.shade500,
                          Colors.purple.shade400,
                          Colors.teal.shade400,
                          Colors.pink.shade400,
                          Colors.indigo.shade400,
                        ];
                        final avatarColor =
                            avatarColors[index % avatarColors.length];

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push('/chat/dm/${agent['id']}');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: avatarColor,
                                        backgroundImage:
                                            agent['avatar_url'] != null
                                            ? NetworkImage(agent['avatar_url'])
                                            : null,
                                        child: agent['avatar_url'] == null
                                            ? Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isOnline
                                                ? Colors.green
                                                : isAway
                                                ? Colors.orange
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.slate900,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  loading: () => const Center(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
              ),
              error: (err, stack) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Failed to load agents',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
              ),
            ),
          ),
        ], // end isTeleCaller check
      ],
    );
  }
}

// -- Recent Sales Placeholder Widget -------------------------------------------

class _RecentSalesPlaceholder extends StatelessWidget {
  const _RecentSalesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Sales history coming soon',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}

// -- Recent Tickets List Widget -------------------------------------------

class _RecentTicketsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return ticketsAsync.when(
      data: (tickets) {
        print('DEBUG: Total tickets: ${tickets.length}');

        // Filter tickets from last 2 days
        final now = DateTime.now();
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        final recentTickets = tickets.where((ticket) {
          if (ticket.createdAt == null) return false;
          final isUnclaimed =
              ticket.assignedTo == null || ticket.assignedTo!.isEmpty;
          return ticket.createdAt!.isAfter(twoDaysAgo) || isUnclaimed;
        }).toList();

        print('DEBUG: Recent tickets (last 2 days): ${recentTickets.length}');

        // Sort: unclaimed first, then by created date (newest first)
        recentTickets.sort((a, b) {
          final aClaimed = a.assignedTo != null && a.assignedTo!.isNotEmpty;
          final bClaimed = b.assignedTo != null && b.assignedTo!.isNotEmpty;

          if (aClaimed != bClaimed) {
            return aClaimed ? 1 : -1; // Unclaimed first
          }

          // Both have same claim status, sort by date
          return (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          );
        });

        if (recentTickets.isEmpty) {
          // If no recent tickets, show some older unclaimed tickets
          final olderUnclaimed = tickets
              .where((ticket) {
                if (ticket.createdAt == null) return false;
                final isClaimed =
                    ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty;
                return !isClaimed; // Show unclaimed tickets regardless of age
              })
              .take(5)
              .toList();

          if (olderUnclaimed.isNotEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'No recent tickets. Showing older unclaimed:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: olderUnclaimed.length,
                    itemBuilder: (context, index) {
                      final ticket = olderUnclaimed[index];
                      return _TicketTile(ticket: ticket);
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No tickets found',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: recentTickets.length,
          itemBuilder: (context, index) {
            final ticket = recentTickets[index];
            return _TicketTile(ticket: ticket);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
          ),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

// -- Ticket Tile Widget -----------------------------------------------------

class _TicketTile extends ConsumerWidget {
  final Ticket ticket;

  const _TicketTile({required this.ticket});

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 2) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getTicketDescription(Ticket ticket) {
    // Use title as primary issue description
    String description = ticket.title;

    // Add description if available and different from title
    if (ticket.description != null &&
        ticket.description!.isNotEmpty &&
        ticket.description != ticket.title) {
      description += '\n\n${ticket.description}';
    }

    // Add category if available
    if (ticket.category != null && ticket.category!.isNotEmpty) {
      description += '\n\nCategory: ${ticket.category}';
    }

    // Add priority if available
    if (ticket.priority != null && ticket.priority!.isNotEmpty) {
      description += '\nPriority: ${ticket.priority}';
    }

    // Limit length for tooltip display
    if (description.length > 200) {
      description = '${description.substring(0, 197)}...';
    }

    return description.isNotEmpty ? description : 'No description available';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isClaimed =
        ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty;
    final customerAsync = ref.watch(ticketCustomerProvider(ticket.customerId));
    final agentsAsync = ref.watch(agentsListProvider);
    final timeAgo = _formatTime(ticket.createdAt);

    // Resolve assigned agent name
    String? assignedAgentName;
    if (isClaimed) {
      final agents = agentsAsync.value ?? [];
      final agent = agents.firstWhere(
        (a) => a['id']?.toString() == ticket.assignedTo,
        orElse: () => <String, dynamic>{},
      );
      final name =
          agent['full_name']?.toString().trim() ??
          agent['username']?.toString().trim() ??
          '';
      if (name.isNotEmpty) assignedAgentName = name;
    }

    // Determine badge label and color based on status
    final String badgeLabel;
    final Color badgeColor;
    final status = ticket.status;

    if (status == 'BillProcessed' || status == 'BillRaised') {
      badgeLabel = 'Billed';
      badgeColor = const Color(0xFF7C3AED); // purple
    } else if (status == 'Resolved' || status == 'Closed') {
      badgeLabel = 'Resolved';
      badgeColor = AppColors.success;
    } else if (isClaimed) {
      badgeLabel = 'Claimed';
      badgeColor = Colors.grey.shade600;
    } else {
      badgeLabel = 'Unclaimed';
      badgeColor = AppColors.error;
    }

    // Card background/border also reflects status
    final Color cardColor;
    final Color cardBorderColor;
    if (status == 'BillProcessed' || status == 'BillRaised') {
      cardColor = const Color(0xFF7C3AED).withValues(alpha: 0.08);
      cardBorderColor = const Color(0xFF7C3AED).withValues(alpha: 0.3);
    } else if (status == 'Resolved' || status == 'Closed') {
      cardColor = AppColors.success.withValues(alpha: 0.07);
      cardBorderColor = AppColors.success.withValues(alpha: 0.3);
    } else if (isClaimed) {
      cardColor = Colors.white.withValues(alpha: 0.05);
      cardBorderColor = Colors.white.withValues(alpha: 0.1);
    } else {
      cardColor = AppColors.error.withValues(alpha: 0.1);
      cardBorderColor = AppColors.error.withValues(alpha: 0.3);
    }

    return customerAsync.when(
      data: (customerData) {
        final companyName =
            customerData?['company_name']?.toString().trim() ?? '';
        final contactPerson =
            customerData?['contact_person']?.toString().trim() ?? '';

        // Use company name as primary, fallback to contact person
        final customerName = companyName.isNotEmpty
            ? companyName
            : (contactPerson.isNotEmpty ? contactPerson : 'Unknown Customer');
        // ignore: unused_local_variable
        final customerEmail = customerData?['contact_email'] ?? '';

        return Tooltip(
          message: _getTicketDescription(ticket),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.4,
          ),
          waitDuration: const Duration(milliseconds: 500),
          showDuration: const Duration(seconds: 3),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cardBorderColor),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to ticket detail
                  context.push('/ticket/${ticket.ticketId}');
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer name and claim status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: customer name + time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Right: claimed badge + agent name stacked
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isClaimed && assignedAgentName != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  assignedAgentName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          'Customer not found',
          style: TextStyle(
            color: Colors.red.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
