import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../chat/presentation/providers/chat_provider.dart'
    show ChatNewMessageEvent;

part 'auth_provider.g.dart';

// Agent model for custom auth
class Agent {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? displayColor;
  final String? avatarUrl;
  final String? teamsUserId;

  Agent({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.displayColor,
    this.avatarUrl,
    this.teamsUserId,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'] ?? json['full_name'],
      role: json['role'],
      displayColor: json['display_color'],
      avatarUrl: json['avatar_url'],
      teamsUserId: json['teams_user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'role': role,
      'display_color': displayColor,
      'avatar_url': avatarUrl,
      'teams_user_id': teamsUserId,
    };
  }
  String get _roleLower => role.trim().toLowerCase();

  bool get isAdmin => _roleLower == 'admin';
  bool get isSupportHead =>
      _roleLower == 'support head' ||
      _roleLower == 'support_head' ||
      _roleLower == 'supporthead' ||
      _roleLower == 'support-head';
  bool get isAccountant => _roleLower == 'accountant';
  bool get isSupport => _roleLower == 'support';
  bool get isAgent => _roleLower == 'agent';
  bool get isSales => _roleLower == 'sales' || _roleLower == 'salesperson';
  bool get isTeleCaller => _roleLower == 'tele caller' || _roleLower == 'telecaller';
  bool get isSoftwareDeveloper => _roleLower == 'software developer' || _roleLower == 'softwaredeveloper';
  bool get isHR => _roleLower == 'hr' || _roleLower == 'human resource' || _roleLower == 'human_resource' || _roleLower == 'human-resource';
  bool get isProjectCoordinator => _roleLower == 'project coordinator' || _roleLower == 'project_coordinator' || _roleLower == 'projectcoordinator';
  bool get isDigitalMarketing => _roleLower == 'digital marketing' || _roleLower == 'digital_marketing' || _roleLower == 'digitalmarketing' || _roleLower == 'digital marketing executive';
}

// Auth state notifier
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  static const _agentPrefsKey = 'auth.agent';
  static const _requestTimeout = Duration(seconds: 6);
  static const _overallTimeout = Duration(seconds: 10);

  @override
  Agent? build() => null;

  Future<bool> login(String username, String password) async {
    final sanitizedUsername = username.trim();
    final sanitizedPassword = password.trim();

    try {
      return await _loginInternal(
        sanitizedUsername,
        sanitizedPassword,
      ).timeout(
        _overallTimeout,
        onTimeout: () {
          appLogger.warning(
            'Login overall timed out',
            context: {'username': sanitizedUsername},
          );
          return false;
        },
      );
    } on TimeoutException catch (e, stackTrace) {
      appLogger.error(
        'Login timed out',
        error: e,
        stackTrace: stackTrace,
        context: {'username': sanitizedUsername},
      );
      return false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Login error: $e');
      }
      appLogger.error(
        'Login failed',
        error: e,
        stackTrace: stackTrace,
        context: {'username': sanitizedUsername},
      );
      return false;
    }
  }

  Future<bool> _loginInternal(String username, String password) async {
    final client = Supabase.instance.client;

    // Fast-path: direct table lookup is faster than RPC and avoids server-side function latency.
    Map<String, dynamic>? agentRow;
    try {
      agentRow = await client
          .from('agents')
          .select('id, username, full_name, role, display_color, avatar_url, teams_user_id')
          .eq('username', username)
          .eq('password', password)
          .limit(1)
          .maybeSingle()
          .timeout(_requestTimeout);
    } on TimeoutException catch (_) {
      appLogger.warning(
        'Direct agent lookup timed out; skipping RPC fallback',
        context: {'username': username},
      );
      return false;
    }

    if (agentRow != null) {
      state = Agent.fromJson(agentRow);
      await _persistAgent(state!);
      await _updateLastSeen(state!.id);
      return true;
    }

    final response = await client
        .rpc(
          'login_agent',
          params: {
            'p_username': username,
            'p_password': password,
          },
        )
        .timeout(_requestTimeout);

    if (response is! Map<String, dynamic>) {
      appLogger.warning(
        'Login RPC returned unexpected payload',
        context: {
          'username': username,
          'payloadType': response.runtimeType.toString(),
        },
      );
      return false;
    }

    if (response['success'] == true && response['agent'] is Map) {
      state = Agent.fromJson(
        Map<String, dynamic>.from(response['agent'] as Map),
      );
      await _persistAgent(state!);
      await _updateLastSeen(state!.id);
      return true;
    }

    appLogger.info(
      'Login RPC returned failure response',
      context: {'username': username, 'response': response},
    );
    return false;
  }

  void logout() {
    // Clear the in-memory set of notified message IDs so the next user
    // doesn't inherit the previous user's notification history.
    ChatNewMessageEvent.resetSession();
    state = null;
    _clearPersistedAgent();
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializedAgent = prefs.getString(_agentPrefsKey);
      if (serializedAgent == null) {
        return;
      }

      final decoded = jsonDecode(serializedAgent);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(_agentPrefsKey);
        return;
      }
      state = Agent.fromJson(decoded);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to restore persisted session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistAgent(Agent agent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_agentPrefsKey, jsonEncode(agent.toJson()));
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to persist agent session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _clearPersistedAgent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_agentPrefsKey);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to clear persisted agent session',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _updateLastSeen(String agentId) async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'last_seen': DateTime.now().toUtc().toIso8601String()})
          .eq('id', agentId);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update last_seen timestamp',
        error: e,
        stackTrace: stackTrace,
        context: {'agentId': agentId},
      );
    }
  }

  Future<bool> updateDisplayColor(String colorHex) async {
    final currentAgent = state;
    if (currentAgent == null) return false;

    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'display_color': colorHex})
          .eq('id', currentAgent.id);

      final updatedAgent = Agent(
        id: currentAgent.id,
        username: currentAgent.username,
        fullName: currentAgent.fullName,
        role: currentAgent.role,
        displayColor: colorHex,
        avatarUrl: currentAgent.avatarUrl,
        teamsUserId: currentAgent.teamsUserId,
      );
      state = updatedAgent;
      await _persistAgent(updatedAgent);
      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update display color',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateAvatarUrl(String avatarUrl) async {
    final currentAgent = state;
    if (currentAgent == null) return false;

    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'avatar_url': avatarUrl})
          .eq('id', currentAgent.id);

      final updatedAgent = Agent(
        id: currentAgent.id,
        username: currentAgent.username,
        fullName: currentAgent.fullName,
        role: currentAgent.role,
        displayColor: currentAgent.displayColor,
        avatarUrl: avatarUrl,
        teamsUserId: currentAgent.teamsUserId,
      );
      state = updatedAgent;
      await _persistAgent(updatedAgent);
      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update avatar URL',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateUsername(String username) async {
    final currentAgent = state;
    if (currentAgent == null) return false;

    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'username': username.trim()})
          .eq('id', currentAgent.id);

      final updatedAgent = Agent(
        id: currentAgent.id,
        username: username.trim(),
        fullName: currentAgent.fullName,
        role: currentAgent.role,
        displayColor: currentAgent.displayColor,
        avatarUrl: currentAgent.avatarUrl,
        teamsUserId: currentAgent.teamsUserId,
      );
      state = updatedAgent;
      await _persistAgent(updatedAgent);
      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update username',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateFullName(String fullName) async {
    final currentAgent = state;
    if (currentAgent == null) return false;

    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'full_name': fullName.trim()})
          .eq('id', currentAgent.id);

      final updatedAgent = Agent(
        id: currentAgent.id,
        username: currentAgent.username,
        fullName: fullName.trim(),
        role: currentAgent.role,
        displayColor: currentAgent.displayColor,
        avatarUrl: currentAgent.avatarUrl,
        teamsUserId: currentAgent.teamsUserId,
      );
      state = updatedAgent;
      await _persistAgent(updatedAgent);
      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update full name',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> updateTeamsUserId(String teamsUserId) async {
    final currentAgent = state;
    if (currentAgent == null) return false;

    try {
      final client = Supabase.instance.client;
      await client
          .from('agents')
          .update({'teams_user_id': teamsUserId.trim()})
          .eq('id', currentAgent.id);

      final updatedAgent = Agent(
        id: currentAgent.id,
        username: currentAgent.username,
        fullName: currentAgent.fullName,
        role: currentAgent.role,
        displayColor: currentAgent.displayColor,
        avatarUrl: currentAgent.avatarUrl,
        teamsUserId: teamsUserId.trim(),
      );
      state = updatedAgent;
      await _persistAgent(updatedAgent);
      return true;
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update Teams user ID',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
