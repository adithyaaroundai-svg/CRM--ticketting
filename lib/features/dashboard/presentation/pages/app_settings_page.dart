import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/layout/main_layout.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../widgets/role_permissions_editor.dart';
import '../widgets/workflow_config_editor.dart';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  ConsumerState<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends ConsumerState<AppSettingsPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  Map<String, bool> _settings = {};
  Map<String, Map<String, bool>> _screenPermissions = {};
  Map<String, Map<String, bool>> _actionPermissions = {};
  Map<String, int> _slaMinutes = {};
  List<String> _visibleStatuses = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _supabase.from('app_settings').select();

      final settings = <String, bool>{};
      Map<String, Map<String, bool>> screenPerms = {};
      Map<String, Map<String, bool>> actionPerms = {};
      Map<String, int> slaMinutes = {
        'critical': 60,
        'high': 180,
        'normal': 480,
        'low': 1440,
      };
      List<String> visibleStatuses = [
        'New',
        'Open',
        'In Progress',
        'On Hold',
        'Waiting for Customer',
        'Resolved',
        'Closed',
        'BillRaised',
        'BillProcessed',
      ];

      for (var setting in response) {
        final key = setting['setting_key'] as String;
        final value = setting['setting_value'];

        if (value is Map<String, dynamic>) {
          if (key == 'role_permissions') {
            // Parse role permissions
            for (final role in value.keys) {
              final roleData = value[role];
              if (roleData is Map<String, dynamic>) {
                final screens = roleData['screens'];
                if (screens is Map<String, dynamic>) {
                  screenPerms[role] = screens.map(
                    (k, v) => MapEntry(k, v == true),
                  );
                }
                final actions = roleData['actions'];
                if (actions is Map<String, dynamic>) {
                  actionPerms[role] = actions.map(
                    (k, v) => MapEntry(k, v == true),
                  );
                }
              }
            }
          } else if (key == 'workflow_config') {
            // Parse workflow config
            final sla = value['sla'];
            if (sla is Map<String, dynamic>) {
              for (final entry in sla.entries) {
                final mins = entry.value;
                if (mins is int) {
                  slaMinutes[entry.key.toLowerCase()] = mins;
                } else if (mins is double) {
                  slaMinutes[entry.key.toLowerCase()] = mins.toInt();
                }
              }
            }
            final statuses = value['visible_statuses'];
            if (statuses is List) {
              visibleStatuses = statuses.whereType<String>().toList();
            }
          } else if (value.containsKey('enabled')) {
            // Simple boolean flag
            settings[key] = value['enabled'] as bool? ?? true;
          }
        }
      }

      setState(() {
        _settings = settings;
        _screenPermissions = screenPerms;
        _actionPermissions = actionPerms;
        _slaMinutes = slaMinutes;
        _visibleStatuses = visibleStatuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      final currentUser = ref.read(authProvider);
      final previousEnabled = _settings[key];
      final nowIso = DateTime.now().toUtc().toIso8601String();
      await _supabase
          .from('app_settings')
          .update({
            'setting_value': {'enabled': value},
            'updated_at': nowIso,
            'updated_by': currentUser?.id,
          })
          .eq('setting_key', key);

      try {
        await _supabase.from('audit_log').insert({
          'ticket_id': null,
          'action': 'setting_toggle',
          'payload': {
            'setting_key': key,
            'previous_enabled': previousEnabled,
            'new_enabled': value,
            'updated_at': nowIso,
          },
          'performed_by': currentUser?.id,
        });
      } catch (_) {}

      setState(() {
        _settings[key] = value;
      });

      ref.invalidate(appSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setting updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveRolePermissions(
    Map<String, Map<String, bool>> screens,
    Map<String, Map<String, bool>> actions,
  ) async {
    try {
      final currentUser = ref.read(authProvider);
      final rolePermsJson = <String, dynamic>{};

      final allRoles = {...screens.keys, ...actions.keys};
      for (final role in allRoles) {
        rolePermsJson[role] = {
          'screens': screens[role] ?? {},
          'actions': actions[role] ?? {},
        };
      }

      await _supabase.from('app_settings').upsert({
        'setting_key': 'role_permissions',
        'setting_value': rolePermsJson,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': currentUser?.id,
      }, onConflict: 'setting_key');

      try {
        await _supabase.from('audit_log').insert({
          'ticket_id': null,
          'action': 'role_permissions_update',
          'payload': {'role_permissions': rolePermsJson},
          'performed_by': currentUser?.id,
        });
      } catch (_) {}

      setState(() {
        _screenPermissions = screens;
        _actionPermissions = actions;
      });

      ref.invalidate(appSettingsProvider);
      ref.invalidate(advancedSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role permissions saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving role permissions: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveWorkflowConfig(
    Map<String, int> sla,
    List<String> statuses,
  ) async {
    try {
      final currentUser = ref.read(authProvider);

      await _supabase.from('app_settings').upsert({
        'setting_key': 'workflow_config',
        'setting_value': {'sla': sla, 'visible_statuses': statuses},
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'updated_by': currentUser?.id,
      }, onConflict: 'setting_key');

      try {
        await _supabase.from('audit_log').insert({
          'ticket_id': null,
          'action': 'workflow_config_update',
          'payload': {'sla_minutes': sla, 'visible_statuses': statuses},
          'performed_by': currentUser?.id,
        });
      } catch (_) {}

      setState(() {
        _slaMinutes = sla;
        _visibleStatuses = statuses;
      });

      ref.invalidate(appSettingsProvider);
      ref.invalidate(advancedSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workflow configuration saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workflow config: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPath: '/settings',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize features, roles, and workflows',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TabBar(
                          controller: _tabController,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.slate600,
                          indicatorColor: AppColors.primary,
                          tabs: const [
                            Tab(
                              icon: Icon(LucideIcons.toggleLeft, size: 18),
                              text: 'Features',
                            ),
                            Tab(
                              icon: Icon(LucideIcons.shield, size: 18),
                              text: 'Role Permissions',
                            ),
                            Tab(
                              icon: Icon(LucideIcons.clock, size: 18),
                              text: 'Workflow & Response Times',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFeaturesTab(),
                        _buildRolePermissionsTab(),
                        _buildWorkflowTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.toggleLeft,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Feature Toggles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enable or disable application-wide features',
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          _buildSettingCard(
            title: 'Chat',
            description: 'Enable or disable chat functionality',
            icon: LucideIcons.messageSquare,
            color: AppColors.primary,
            settingKey: 'enable_chat',
            value: _settings['enable_chat'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Billing',
            description: 'Enable or disable billing features',
            icon: LucideIcons.receipt,
            color: AppColors.success,
            settingKey: 'enable_billing',
            value: _settings['enable_billing'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Ticket Creation',
            description: 'Allow users to create new tickets',
            icon: LucideIcons.plus,
            color: AppColors.info,
            settingKey: 'enable_ticket_creation',
            value: _settings['enable_ticket_creation'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Reports',
            description: 'Enable or disable reports access',
            icon: LucideIcons.barChart,
            color: AppColors.warning,
            settingKey: 'enable_reports',
            value: _settings['enable_reports'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Notifications',
            description: 'Enable or disable system notifications',
            icon: LucideIcons.bell,
            color: AppColors.error,
            settingKey: 'enable_notifications',
            value: _settings['enable_notifications'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Wiki / Knowledge Base',
            description:
                'Enable or disable the wiki screen and related workflows',
            icon: LucideIcons.bookOpen,
            color: AppColors.info,
            settingKey: 'enable_wiki',
            value: _settings['enable_wiki'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Deals / Sales Pipeline',
            description: 'Enable or disable the deals pipeline screens',
            icon: LucideIcons.briefcase,
            color: AppColors.primary,
            settingKey: 'enable_deals',
            value: _settings['enable_deals'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Global Search',
            description: 'Enable or disable global search from the sidebar',
            icon: LucideIcons.search,
            color: AppColors.slate700,
            settingKey: 'enable_global_search',
            value: _settings['enable_global_search'] ?? true,
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: 'Moderator Force Resolve',
            description: 'Allow moderators to force resolve tickets to billing',
            icon: LucideIcons.zap,
            color: AppColors.warning,
            settingKey: 'enable_moderator_force_resolve',
            value: _settings['enable_moderator_force_resolve'] ?? true,
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: RolePermissionsEditor(
        screenPermissions: _screenPermissions,
        actionPermissions: _actionPermissions,
        onSave: _saveRolePermissions,
      ),
    );
  }

  Widget _buildWorkflowTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: WorkflowConfigEditor(
        slaMinutes: _slaMinutes,
        visibleStatuses: _visibleStatuses,
        onSave: _saveWorkflowConfig,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String settingKey,
    required bool value,
  }) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) => _updateSetting(settingKey, newValue),
          ),
        ],
      ),
    );
  }
}
