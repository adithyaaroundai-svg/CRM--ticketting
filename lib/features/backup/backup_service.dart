import 'dart:convert';
import 'dart:js_interop';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import 'backup_service_native.dart'
    if (dart.library.html) 'backup_service_web_stub.dart' as native_save;

/// Result returned after a backup completes or fails.
class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;

  const BackupResult.success(this.filePath)
      : success = true,
        error = null;

  const BackupResult.failure(this.error)
      : success = false,
        filePath = null;
}

/// Key used to persist the last backup timestamp in SharedPreferences.
const _kLastBackupKey = 'backup.last_backup_at';

/// Reads the last backup timestamp from local storage.
Future<DateTime?> getLastBackupTime() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kLastBackupKey);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

/// Saves the current time as the last backup timestamp.
Future<void> _saveLastBackupTime() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastBackupKey, DateTime.now().toIso8601String());
}

/// Main backup entry point. Fetches all data, zips it, then either:
///  - Web  : triggers a browser download via a Blob URL
///  - Native: saves to the Downloads / Documents folder
Future<BackupResult> createLocalBackup({
  required String agentId,
  required String agentName,
  required String agentRole,
}) async {
  try {
    final client = Supabase.instance.client;

    // ── 1. Fetch tickets ──────────────────────────────────────────────────
    final ticketsRaw = await client
        .from('tickets')
        .select()
        .order('created_at', ascending: false);

    // ── 2. Fetch customers ────────────────────────────────────────────────
    final customersRaw = await client
        .from('customers')
        .select()
        .order('company_name', ascending: true);

    // ── 3. Fetch global chat messages ─────────────────────────────────────
    final globalChatRaw = await client
        .from('chat_messages')
        .select()
        .isFilter('receiver_id', null)
        .order('created_at', ascending: true);

    // ── 4. Fetch DM messages involving this agent ─────────────────────────
    final dmSentRaw = await client
        .from('chat_messages')
        .select()
        .eq('sender_id', agentId)
        .not('receiver_id', 'is', null)
        .order('created_at', ascending: true);

    final dmReceivedRaw = await client
        .from('chat_messages')
        .select()
        .eq('receiver_id', agentId)
        .order('created_at', ascending: true);

    // Merge & deduplicate DMs by id
    final dmMap = <String, Map<String, dynamic>>{};
    for (final m in [...dmSentRaw, ...dmReceivedRaw]) {
      dmMap[m['id']?.toString() ?? ''] = m;
    }
    final dmMessagesRaw = dmMap.values.toList()
      ..sort((a, b) {
        final aTime = a['created_at']?.toString() ?? '';
        final bTime = b['created_at']?.toString() ?? '';
        return aTime.compareTo(bTime);
      });

    // ── 5. Fetch ticket comments ──────────────────────────────────────────
    final commentsRaw = await client
        .from('ticket_comments')
        .select()
        .order('created_at', ascending: true);

    // ── 6. Build backup_info metadata ─────────────────────────────────────
    final backupInfo = {
      'backup_created_at': DateTime.now().toIso8601String(),
      'agent_id': agentId,
      'agent_name': agentName,
      'agent_role': agentRole,
      'app_version': '1.0.0',
      'counts': {
        'tickets': ticketsRaw.length,
        'customers': customersRaw.length,
        'global_chat_messages': globalChatRaw.length,
        'dm_messages': dmMessagesRaw.length,
        'ticket_comments': commentsRaw.length,
      },
    };

    // ── 7. Build the zip archive in memory ────────────────────────────────
    final archive = Archive();

    void addJsonFile(String name, dynamic data) {
      final jsonBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(data),
      );
      archive.addFile(ArchiveFile(name, jsonBytes.length, jsonBytes));
    }

    addJsonFile('backup_info.json', backupInfo);
    addJsonFile('tickets.json', ticketsRaw);
    addJsonFile('customers.json', customersRaw);
    addJsonFile('global_chat.json', globalChatRaw);
    addJsonFile('dm_messages.json', dmMessagesRaw);
    addJsonFile('ticket_comments.json', commentsRaw);

    // ── 8. Encode to zip bytes ────────────────────────────────────────────
    final zipBytes = ZipEncoder().encode(archive);

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'tallyCare_backup_$timestamp.zip';

    // ── 9. Save — web vs native ───────────────────────────────────────────
    String savedPath;

    if (kIsWeb) {
      // Convert to JS-interop Uint8Array and trigger browser download
      final uint8 = Uint8List.fromList(zipBytes);
      final jsArray = uint8.toJS;
      final blob = web.Blob(
        [jsArray].toJS,
        web.BlobPropertyBag(type: 'application/zip'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName;
      web.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
      savedPath = 'Your browser Downloads folder  ($fileName)';
    } else {
      savedPath = await native_save.saveZipToDownloads(zipBytes, fileName);
    }

    // ── 10. Persist timestamp ─────────────────────────────────────────────
    await _saveLastBackupTime();

    return BackupResult.success(savedPath);
  } catch (e) {
    return BackupResult.failure(e.toString());
  }
}

/// Riverpod provider that exposes the last backup time reactively.
/// Invalidate after a backup to trigger a UI refresh.
final lastBackupTimeProvider = FutureProvider<DateTime?>((ref) async {
  return getLastBackupTime();
});
