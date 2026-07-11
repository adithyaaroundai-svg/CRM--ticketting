import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/design_system/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/agent_dashboard_page.dart';
import 'features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'features/chat/presentation/pages/global_chat_page.dart';
import 'features/chat/presentation/pages/sales_chat_page.dart';
import 'features/chat/presentation/pages/all_aroundtally_chat_page.dart';
import 'features/chat/presentation/pages/custom_channel_chat_page.dart';
import 'features/sales/presentation/pages/leads_page.dart';
import 'features/chat/presentation/pages/direct_message_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/profile_page.dart';
import 'features/auth/presentation/pages/add_user_page.dart';
import 'features/auth/presentation/pages/users_page.dart';
import 'features/auth/presentation/pages/reset_password_new_page.dart';
import 'features/auth/presentation/pages/reset_password_verify_page.dart';
import 'features/auth/presentation/pages/admin_signup_email_verify_page.dart';
import 'features/auth/presentation/pages/admin_signup_details_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/tickets/presentation/pages/ticket_detail_page.dart';
import 'features/tickets/presentation/pages/tickets_page.dart';
import 'features/tickets/presentation/pages/bills_page.dart';
import 'features/deals/presentation/pages/deals_tracker_page.dart';
import 'features/customers/presentation/pages/customers_page.dart';
import 'features/customers/presentation/pages/amc_reminder_page.dart';
import 'features/customers/presentation/pages/customer_detail_page.dart';
import 'features/customers/presentation/pages/add_customer_page.dart';
import 'features/customers/presentation/pages/edit_customer_page.dart';
import 'features/customers/presentation/widgets/customer_history_sheet.dart';
import 'features/dashboard/presentation/pages/support_dashboard_page.dart';
import 'features/tickets/presentation/pages/past_tickets_page.dart';
import 'features/sales/presentation/pages/sales_opportunity_page.dart';
import 'features/sales/presentation/pages/sales_dashboard_page.dart';
import 'features/dashboard/presentation/pages/reports_page.dart';
import 'features/dashboard/presentation/pages/revenue_page.dart';
import 'features/dashboard/presentation/pages/app_settings_page.dart';
import 'features/productivity/presentation/pages/notifications_page.dart';
import 'features/productivity/presentation/pages/deals_page.dart';
import 'features/dashboard/presentation/providers/app_settings_provider.dart';
import 'features/sales/presentation/pages/proposal_generator_page.dart';

import 'core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.init();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ybmxpmsiihtasyjwxtol.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlibXhwbXNpaWh0YXN5and4dG9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5MDExNTEsImV4cCI6MjA4NzQ3NzE1MX0.dOoJWDf4j_etF0NTq4uuaVG47e0y_pDe-AdgDRhWI68',
  );

  final container = ProviderContainer();
  await container.read(authProvider.notifier).restoreSession();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TallyCareApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final appSettingsAsync = ref.watch(appSettingsProvider);
  final appSettings = appSettingsAsync.maybeWhen(
    data: (value) => value,
    orElse: () => null,
  );
  final advancedSettingsAsync = ref.watch(advancedSettingsProvider);
  final advancedSettings = advancedSettingsAsync.maybeWhen(
    data: (value) => value,
    orElse: () => null,
  );

  final isLoggedIn = authState != null;
  final isAdmin = authState?.isAdmin ?? false;
  final isSupportHead = authState?.isSupportHead ?? false;
  final isAccountant = authState?.isAccountant ?? false;
  final isSupport = authState?.isSupport ?? false;
  final isHR = authState?.isHR ?? false;
  final isProjectCoordinator = authState?.isProjectCoordinator ?? false;
  final isSales = authState?.isSales ?? false;

  return GoRouter(
    debugLogDiagnostics: false,
    initialLocation: authState == null ? '/login' : '/',
    redirect: (context, state) {
      final isLoggingIn = state.uri.toString() == '/login';
      final isResettingPassword = state.matchedLocation.startsWith(
        '/reset-password',
      );
      final isAdminSignup = state.matchedLocation.startsWith('/admin-signup');
      
      // Redirect to login if not authenticated
      if (!isLoggedIn &&
          !isLoggingIn &&
          !isResettingPassword &&
          !isAdminSignup) {
        return '/login';
      }

      // If logged in and hitting /login directly, send to role-specific home
      if (isLoggedIn && isLoggingIn) {
        if (isAdmin) return '/admin';
        if (isAccountant) return '/accountant';
        if (isSupport || isHR || isProjectCoordinator) return '/chat';
        if (isSales) return '/sales';
        if (isSupportHead) return '/';
        return '/';
      }

      // Role-based access control
      if (isAdmin && state.matchedLocation == '/') return '/admin';
      if (isAccountant && state.matchedLocation == '/') {
        return '/accountant';
      }
      if ((isSupport || isHR || isProjectCoordinator) && state.matchedLocation == '/') {
        return '/chat';
      }
      if (isSales && state.matchedLocation == '/') {
        return '/sales';
      }

      final location = state.matchedLocation;
      String? featureKey;
      if (location.startsWith('/reports')) {
        featureKey = 'enable_reports';
      } else if (location.startsWith('/deals')) {
        featureKey = 'enable_deals';
      } else if (location.startsWith('/notifications')) {
        featureKey = 'enable_notifications';
      }

      if (featureKey != null && appSettings != null) {
        final enabled = appSettings[featureKey] ?? true;
        if (!enabled) {
          if (!isLoggedIn) return '/login';
          if (isAdmin) return '/admin';
          if (isAccountant) return '/accountant';
          if (isSupport) return '/chat';
          if (isSupportHead) return '/';
          return '/';
        }
      }

      // Per-role screen visibility using advanced settings (role_permissions)
      if (advancedSettings != null && isLoggedIn) {
        String? screenId;
        if (location == '/') {
          screenId = 'dashboard';
        } else if (location.startsWith('/reports')) {
          screenId = 'reports';
        } else if (location.startsWith('/deals')) {
          screenId = 'deals';
        } else if (location.startsWith('/settings')) {
          screenId = 'settings';
        }

        if (screenId != null) {
          final roleName = authState.role;
          final canSee = advancedSettings.canRoleSeeScreen(
            roleName,
            screenId,
          );
          if (!canSee) {
            if (isAdmin) return '/admin';
            if (isAccountant) return '/accountant';
            if (isSupport) return '/chat';
            if (isSupportHead) return '/';
            return '/';
          }
        }
      }

      if (!isAdmin && !isAccountant && location.startsWith('/revenue')) {
        if (!isLoggedIn) return '/login';
        if (isSupport || isHR || isProjectCoordinator) return '/chat';
        if (isSupportHead) return '/';
        return '/';
      }

      // Prevent unauthorized access (basic)
      // Note: A more robust RBAC would check every route against the role
      if (!isAdmin &&
          (state.matchedLocation == '/admin' ||
              state.matchedLocation.startsWith('/admin/'))) {
        return '/login';
      }
      if (!isAccountant && state.matchedLocation.startsWith('/accountant')) {
        return '/login';
      }
      if (!isSupport && !isHR && !isProjectCoordinator && !isAccountant && !isAdmin && state.matchedLocation.startsWith('/support')) {
        return '/login';
      }
      if (!isAdmin && state.matchedLocation.startsWith('/settings')) {
        return '/login';
      }
      if (!isAdmin &&
          !isAccountant &&
          !isSupport &&
          !isHR &&
          !isProjectCoordinator &&
          !isSupportHead &&
          state.matchedLocation.startsWith('/reports')) {
        return '/login';
      }

      // Sales channel access: only specific agent IDs are allowed
      if (state.matchedLocation.startsWith('/sales-channel')) {
        const allowedSalesChannelIds = {
          '0a5aeeb8-9544-4dc8-920f-e26c192b0dd3',
          '1f4d7758-12ba-43eb-9e47-cc0c95b740b8',
          '14db36db-0cb9-44ef-8032-d9610b3bc797',
          'b77b3738-4dfc-4515-a1fd-d6fb170423f4',
          'd8aa6435-9e02-4bab-9acc-ae1f5f3d6a1c',
          '5a06a8df-97f1-4dbf-bc13-9724a3c779c1',
        };
        final userId = authState?.id ?? '';
        if (!allowedSalesChannelIds.contains(userId)) {
          if (!isLoggedIn) return '/login';
          if (isAdmin) return '/admin';
          if (isAccountant) return '/accountant';
          if (isSupport) return '/chat';
          if (isSales) return '/sales';
          return '/';
        }
      }

      // Deals tracker access: only George is allowed
      if (state.matchedLocation.startsWith('/deals-tracker')) {
        const allowedDealsTrackerIds = {
          '0a5aeeb8-9544-4dc8-920f-e26c192b0dd3', // George
        };
        final userId = authState?.id ?? '';
        if (!allowedDealsTrackerIds.contains(userId)) {
          if (!isLoggedIn) return '/login';
          if (isAdmin) return '/admin';
          if (isAccountant) return '/accountant';
          if (isSupport) return '/chat';
          if (isSales) return '/sales';
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AgentDashboardPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/accountant',
        builder: (context, state) => const BillsPage(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportDashboardPage(),
      ),
      GoRoute(
        path: '/sales',
        builder: (context, state) => const SalesDashboardPage(),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) {
          final view = state.uri.queryParameters['view'];
          return TicketsPage(initialView: view);
        },
      ),
      GoRoute(
        path: '/past-tickets',
        builder: (context, state) => const PastTicketsPage(),
      ),
      GoRoute(path: '/bills', builder: (context, state) => const BillsPage()),
      GoRoute(
        path: '/customers',
        builder: (context, state) {
          final filter = state.uri.queryParameters['filter'];
          final initialFilter = filter == 'expired' ? 'Expired' : 'All';
          return CustomersPage(initialFilter: initialFilter);
        },
      ),
      GoRoute(
        path: '/amc-reminder',
        builder: (context, state) => const AmcReminderPage(),
      ),
      GoRoute(
        path: '/customers/add',
        builder: (context, state) => const AddCustomerPage(),
      ),
      GoRoute(
        path: '/customer/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailPage(customerId: id);
        },
      ),
      GoRoute(
        path: '/customer/:id/history',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerHistoryPage(customerId: id);
        },
      ),
      GoRoute(
        path: '/customer/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditCustomerPage(customerId: id);
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TicketDetailPage(ticketId: id);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(path: '/users', builder: (context, state) => const UsersPage()),
      GoRoute(
        path: '/users/add',
        builder: (context, state) => const AddUserPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordVerifyPage(),
      ),
      GoRoute(
        path: '/reset-password/new/:agentId',
        builder: (context, state) {
          final agentId = state.pathParameters['agentId']!;
          final extra = state.extra;
          String username = '';
          if (extra is Map) {
            final u = extra['username'];
            if (u is String) username = u;
          }
          return ResetPasswordNewPage(agentId: agentId, username: username);
        },
      ),
      GoRoute(
        path: '/admin-signup',
        builder: (context, state) => const AdminSignupEmailVerifyPage(),
      ),
      GoRoute(
        path: '/admin-signup/details',
        builder: (context, state) {
          final extra = state.extra;
          String email = '';
          if (extra is Map) {
            final e = extra['email'];
            if (e is String) email = e;
          }
          return AdminSignupDetailsPage(email: email);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/revenue',
        builder: (context, state) => const RevenuePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AppSettingsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/sales-opportunity',
        builder: (context, state) => const SalesOpportunityPage(),
      ),
      GoRoute(path: '/deals', builder: (context, state) => const DealsPage()),
      GoRoute(
        path: '/proposal-generator',
        builder: (context, state) => const ProposalGeneratorPage(),
      ),
      GoRoute(
        path: '/leads',
        builder: (context, state) => const LeadsPage(),
      ),
      GoRoute(
        path: '/deals-tracker',
        builder: (context, state) => const DealsTrackerPage(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const GlobalChatPage(),
      ),
      GoRoute(
        path: '/sales-channel',
        builder: (context, state) => const SalesChatPage(),
      ),
      GoRoute(
        path: '/channel/all-aroundtally',
        builder: (context, state) => const AllAroundTallyChatPage(),
      ),
      GoRoute(
        path: '/chat/dm/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return DirectMessagePage(partnerId: userId);
        },
      ),
      GoRoute(
        path: '/c/:channelId',
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return CustomChannelChatPage(channelId: channelId);
        },
      ),
    ],
  );
});

class TallyCareApp extends ConsumerWidget {
  const TallyCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TallyCare',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
