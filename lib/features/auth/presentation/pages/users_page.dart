import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/auth_provider.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  String _selectedRole = 'all';

  // Check if current user can manage users (admin or HR)
  bool get _canManageUsers {
    final currentUser = ref.read(authProvider);
    return currentUser?.isAdmin == true || currentUser?.isHR == true;
  }

  // Check if current user can delete users and change roles (admin only)
  bool get _canDeleteAndEditRoles {
    final currentUser = ref.read(authProvider);
    return currentUser?.isAdmin == true;
  }

  final List<String> _roles = [
    'all',
    'Admin',
    'Support Head',
    'Support',
    'Accountant',
    'Tele Caller',
    'Software Developer',
    'Digital Marketing Executive',
    'HR',
    'Project Coordinator',
  ];

  Future<List<User>> _fetchUsers() async {
    final supabase = Supabase.instance.client;
    final List<User> allUsers = [];

    // Only fetch from agents table since moderators and accountants tables don't exist yet
    try {
      final response = await supabase.from('agents').select('*');
      final users = (response as List<dynamic>)
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
      allUsers.addAll(users);
    } catch (e) {
      debugPrint('Error fetching agents: $e');
    }

    return allUsers;
  }

  Future<void> _deleteUser(User user) async {
    final supabase = Supabase.instance.client;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Deleting ${user.fullName} will unassign their tickets and permanently remove their notifications and activity history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deleting user…'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await supabase
          .from('tickets')
          .update({'assigned_to': null})
          .eq('assigned_to', user.id);

      await supabase.from('ticket_remarks').delete().eq('agent_id', user.id);
      await supabase.from('notifications').delete().eq('user_id', user.id);
      await supabase.from('activities').delete().eq('agent_id', user.id);
      await supabase.from('agents').delete().eq('id', user.id);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateUserRole(User user, String newRole) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase
          .from('agents')
          .update({'role': newRole})
          .eq('id', user.id);

      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} role updated to $newRole'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating role: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showEditRoleDialog(User user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Change Role for ${user.fullName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select new role:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ..._roles.where((r) => r != 'all').map((role) {
                  return RadioListTile<String>(
                    title: Text(_getRoleDisplayName(role)),
                    value: role,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedRole = value!;
                      });
                    },
                  );
                }).toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (selectedRole != user.role) {
                    _updateUserRole(user, selectedRole);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPath: '/users',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'User Management',
                subtitle: 'Manage system users and permissions',
                onBack: () {
                  final currentUser = ref.read(authProvider);
                  if (currentUser?.isAdmin == true) {
                    context.go('/admin');
                  } else if (currentUser?.isAccountant == true) {
                    context.go('/accountant');
                  } else if (currentUser?.isSupport == true || currentUser?.isHR == true) {
                    context.go('/chat');
                  } else if (currentUser?.isSales == true) {
                    context.go('/sales');
                  } else {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_canManageUsers)
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/users/add'),
                    icon: const Icon(LucideIcons.userPlus, size: 18),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              if (_canManageUsers) const SizedBox(height: 24),

              // Filter Section
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.filter, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'Filter by Role:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: _roles.map((role) {
                            final isSelected = _selectedRole == role;
                            return FilterChip(
                              label: Text(
                                role == 'all'
                                    ? 'All Users'
                                    : _getRoleDisplayName(role),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedRole = role);
                                }
                              },
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                              checkmarkColor: AppColors.primary,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Users List
              FutureBuilder<List<User>>(
                future: _fetchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading users: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];

                  final filteredUsers = _selectedRole == 'all'
                      ? users
                      : users
                            .where(
                              (u) =>
                                  u.role.toLowerCase() ==
                                  _selectedRole.toLowerCase(),
                            )
                            .toList();

                  if (filteredUsers.isEmpty) {
                    return EmptyStateCard(
                      icon: LucideIcons.users,
                      title: 'No users found',
                      subtitle: _selectedRole == 'all'
                          ? 'No users in the system yet'
                          : 'No ${_getRoleDisplayName(_selectedRole).toLowerCase()}s found',
                      actionLabel: _canManageUsers ? 'Add User' : null,
                      onAction: _canManageUsers ? () => context.go('/users/add') : null,
                    );
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Column(
                      children: filteredUsers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        final isLast = index == filteredUsers.length - 1;
                        return _UserTile(
                          user: user,
                          onDelete: _canDeleteAndEditRoles ? () => _deleteUser(user) : null,
                          onEditRole: _canDeleteAndEditRoles ? () => _showEditRoleDialog(user) : null,
                          isLast: isLast,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'support':
        return 'Support';
      case 'support head':
        return 'Support Head';
      case 'admin':
        return 'Admin';
      case 'accountant':
        return 'Accountant';
      case 'project coordinator':
        return 'Project Coordinator';
      default:
        return role;
    }
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final VoidCallback? onDelete;
  final VoidCallback? onEditRole;
  final bool isLast;

  const _UserTile({
    required this.user,
    this.onDelete,
    this.onEditRole,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
            child: Icon(
              _getRoleIcon(user.role),
              color: _getRoleColor(user.role),
            ),
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleDisplayName(user.role),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRoleColor(user.role),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: (onDelete != null || onEditRole != null)
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    } else if (value == 'editRole' && onEditRole != null) {
                      onEditRole!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEditRole != null)
                      const PopupMenuItem(
                        value: 'editRole',
                        child: Row(
                          children: [
                            Icon(LucideIcons.userCog, color: AppColors.primary, size: 16),
                            SizedBox(width: 8),
                            Text('Change Role'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2, color: AppColors.error, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Delete User',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              : null,
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'support':
        return 'Support';
      case 'agent':
        return 'Agent';
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      case 'accountant':
        return 'Accountant';
      case 'hr':
        return 'HR';
      case 'project coordinator':
        return 'Project Coordinator';
      default:
        return role;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'support':
        return LucideIcons.headphones;
      case 'support head':
        return LucideIcons.user;
      case 'accountant':
        return LucideIcons.calculator;
      case 'admin':
        return LucideIcons.crown;
      case 'hr':
        return LucideIcons.users;
      case 'project coordinator':
        return LucideIcons.clipboardList;
      default:
        return LucideIcons.user;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'support':
        return AppColors.info;
      case 'support head':
        return AppColors.info;
      case 'accountant':
        return AppColors.warning;
      case 'admin':
        return AppColors.primary;
      case 'hr':
        return AppColors.success;
      case 'project coordinator':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
