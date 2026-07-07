import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_card.dart';

/// Widget for editing per-role screen and action permissions.
class RolePermissionsEditor extends StatefulWidget {
  final Map<String, Map<String, bool>> screenPermissions;
  final Map<String, Map<String, bool>> actionPermissions;
  final void Function(
    Map<String, Map<String, bool>> screens,
    Map<String, Map<String, bool>> actions,
  )
  onSave;

  const RolePermissionsEditor({
    super.key,
    required this.screenPermissions,
    required this.actionPermissions,
    required this.onSave,
  });

  @override
  State<RolePermissionsEditor> createState() => _RolePermissionsEditorState();
}

class _RolePermissionsEditorState extends State<RolePermissionsEditor> {
  late Map<String, Map<String, bool>> _screenPermissions;
  late Map<String, Map<String, bool>> _actionPermissions;
  bool _hasChanges = false;

  static const roles = ['Admin', 'Support Head', 'Support', 'Accountant'];
  static const screens = [
    ('dashboard', 'Dashboard', LucideIcons.layoutDashboard),
    ('tickets', 'Tickets', LucideIcons.ticket),
    ('customers', 'Customers', LucideIcons.users),
    ('reports', 'Reports', LucideIcons.barChart),
    ('wiki', 'Wiki', LucideIcons.bookOpen),
    ('deals', 'Deals', LucideIcons.briefcase),
    ('settings', 'Settings', LucideIcons.settings),
  ];
  static const actions = [
    ('force_resolve', 'Force Resolve'),
    ('assign_any', 'Assign Any Ticket'),
    ('billing_override', 'Billing Override'),
    ('ticket_claim', 'Claim Tickets'),
  ];

  @override
  void initState() {
    super.initState();
    _screenPermissions = _deepCopy(widget.screenPermissions);
    _actionPermissions = _deepCopy(widget.actionPermissions);
    _ensureAllRolesExist();
  }

  Map<String, Map<String, bool>> _deepCopy(Map<String, Map<String, bool>> src) {
    return src.map((k, v) => MapEntry(k, Map<String, bool>.from(v)));
  }

  void _ensureAllRolesExist() {
    for (final role in roles) {
      _screenPermissions.putIfAbsent(role, () => {});
      _actionPermissions.putIfAbsent(role, () => {});
    }
  }

  bool _getScreenPerm(String role, String screen) {
    return _screenPermissions[role]?[screen] ??
        _defaultScreenPerm(role, screen);
  }

  bool _getActionPerm(String role, String action) {
    return _actionPermissions[role]?[action] ??
        _defaultActionPerm(role, action);
  }

  bool _defaultScreenPerm(String role, String screen) {
    // Sensible defaults matching current hard-coded behavior
    switch (screen) {
      case 'settings':
        return role == 'Admin';
      case 'reports':
        return role == 'Admin' ||
            role == 'Support Head' ||
            role == 'Accountant';
      case 'deals':
        return role == 'Admin' ||
            role == 'Support Head' ||
            role == 'Accountant';
      case 'tickets':
        return role != 'Accountant';
      default:
        return true;
    }
  }

  bool _defaultActionPerm(String role, String action) {
    switch (action) {
      case 'force_resolve':
        return role == 'Support Head' || role == 'Admin';
      case 'assign_any':
        return role == 'Admin' || role == 'Support Head';
      case 'billing_override':
        return role == 'Admin' || role == 'Accountant';
      case 'ticket_claim':
        return role == 'Support' || role == 'Agent';
      default:
        return true;
    }
  }

  void _setScreenPerm(String role, String screen, bool value) {
    setState(() {
      _screenPermissions.putIfAbsent(role, () => {});
      _screenPermissions[role]![screen] = value;
      _hasChanges = true;
    });
  }

  void _setActionPerm(String role, String action, bool value) {
    setState(() {
      _actionPermissions.putIfAbsent(role, () => {});
      _actionPermissions[role]![action] = value;
      _hasChanges = true;
    });
  }

  void _save() {
    widget.onSave(_screenPermissions, _actionPermissions);
    setState(() => _hasChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.shield, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Role Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const Spacer(),
            if (_hasChanges)
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save, size: 16),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Configure which screens and actions are available to each role',
          style: TextStyle(fontSize: 13, color: AppColors.slate500),
        ),
        const SizedBox(height: 24),

        // Screen permissions
        const Text(
          'Screen Visibility',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 44,
              columns: [
                const DataColumn(label: Text('Screen')),
                ...roles.map((r) => DataColumn(label: Text(r))),
              ],
              rows: screens.map((screen) {
                final (id, label, icon) = screen;
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: AppColors.slate600),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    ),
                    ...roles.map(
                      (role) => DataCell(
                        Checkbox(
                          value: _getScreenPerm(role, id),
                          onChanged: (v) => _setScreenPerm(role, id, v ?? true),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action permissions
        const Text(
          'Action Permissions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 44,
              columns: [
                const DataColumn(label: Text('Action')),
                ...roles.map((r) => DataColumn(label: Text(r))),
              ],
              rows: actions.map((action) {
                final (id, label) = action;
                return DataRow(
                  cells: [
                    DataCell(Text(label)),
                    ...roles.map(
                      (role) => DataCell(
                        Checkbox(
                          value: _getActionPerm(role, id),
                          onChanged: (v) => _setActionPerm(role, id, v ?? true),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
