import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:http/http.dart' as http;

import '../../../../core/design_system/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/ticket_remarks_provider.dart';
import 'voice_note_widget.dart';

class TicketRemarksSection extends ConsumerStatefulWidget {
  final String ticketId;
  final String? currentStage;

  const TicketRemarksSection({
    super.key,
    required this.ticketId,
    this.currentStage,
  });

  @override
  ConsumerState<TicketRemarksSection> createState() =>
      _TicketRemarksSectionState();
}

class _TicketRemarksSectionState extends ConsumerState<TicketRemarksSection> {
  final _remarkController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isSubmitting = false;
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  final List<Map<String, dynamic>> _optimisticRemarks = [];

  @override
  void dispose() {
    _remarkController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      debugPrint('Starting recording...');

      // Check and request permissions (only for mobile platforms)
      String? path;
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        debugPrint('Permission status: $status');
        if (status != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Microphone permission is required'),
              ),
            );
          }
          return;
        }

        // Get temporary directory for mobile
        final tempDir = await getTemporaryDirectory();
        debugPrint('Temp directory: ${tempDir.path}');
        path =
            '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.webm';
        debugPrint('Recording path: $path');

        // Configure and start recording for mobile
        debugPrint('Starting audio recorder...');
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            bitRate: 128000,
            sampleRate: 48000,
          ),
          path: path,
        );
        debugPrint('Audio recorder started successfully');
      } else {
        // For web, we need to provide a path even if it's not used
        debugPrint('Starting audio recorder for web...');
        path = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.webm';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            bitRate: 128000,
            sampleRate: 48000,
          ),
          path: path,
        );
        debugPrint('Web audio recorder started successfully');
      }

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingPath = kIsWeb ? null : path;
          _recordingDuration = 0;
        });

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _recordingDuration++);
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
    });

    if (cancel) {
      if (path != null) {
        try {
          await File(path).delete();
        } catch (e) {
          debugPrint('Error deleting recording: $e');
        }
      }
      _recordingPath = null;
    } else if (path != null) {
      _recordingPath = path;
      // Submit the voice note
      await _submitRemark(audioPath: path);
      _recordingPath = null;
    }
  }

  Future<void> _submitRemark({String? audioPath}) async {
    final text = _remarkController.text.trim();
    if (text.isEmpty && audioPath == null) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;

      if (audioPath != null) {
        // Upload audio file to Supabase Storage
        final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';

        if (kIsWeb) {
          // For web, the audioPath is actually a blob URL
          // We need to fetch the blob and upload it
          final response = await http.get(Uri.parse(audioPath));
          final bytes = response.bodyBytes;

          // Upload bytes directly for web
          await supabase.storage
              .from('voice_notes')
              .uploadBinary(fileName, bytes);
        } else {
          // For mobile, use file path
          final file = File(audioPath);
          await supabase.storage.from('voice_notes').upload(fileName, file);
          // Clean up local file after upload
          await file.delete();
        }

        // Get the public URL of the uploaded file
        final publicUrl = supabase.storage
            .from('voice_notes')
            .getPublicUrl(fileName);

        debugPrint('Voice note uploaded successfully. Public URL: $publicUrl');

        // Validate the URL before storing
        if (publicUrl.isEmpty || !publicUrl.startsWith('http')) {
          throw Exception('Failed to generate valid public URL for voice note');
        }

        // Insert into ticket_remarks table with voice note data
        await supabase.from('ticket_remarks').insert({
          'ticket_id': widget.ticketId,
          'agent_id': currentUser.id,
          'remark_type': 'voice',
          'voice_url': publicUrl,
          'duration_seconds': _recordingDuration,
          'remark':
              'Voice note (${_formatDuration(_recordingDuration)})', // Provide default text for voice notes
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voice note sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Handle text remark (existing functionality)
        await supabase.from('ticket_remarks').insert({
          'ticket_id': widget.ticketId,
          'agent_id': currentUser.id, // Fixed: was missing agent_id
          'remark_type': 'text',
          'remark': text,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error submitting remark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    // Clear input
    _remarkController.clear();
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final remarksAsync = ref.watch(ticketRemarksProvider(widget.ticketId));

    return Column(
      children: [
        SizedBox(
          height: 500,
          child: remarksAsync.when(
            data: (remarks) {
              final merged = <Map<String, dynamic>>[
                ..._optimisticRemarks,
                ...remarks,
              ];

              if (merged.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.messageSquare,
                        size: 48,
                        color: AppColors.slate300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No remarks yet',
                        style: TextStyle(
                          color: AppColors.slate500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: _scrollController,
                reverse: true, // Chat style
                padding: const EdgeInsets.all(16),
                itemCount: merged.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final remark = merged[index];
                  return _RemarkCard(
                    remark: remark,
                    agentId:
                        remark['agent_id']
                            as String?, // Null for customer remarks
                    isMe:
                        remark['agent_id'] != null &&
                        ref.read(authProvider)?.id == remark['agent_id'],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: _isRecording
                ? Row(
                    children: [
                      const Icon(LucideIcons.mic, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(
                        _formatDuration(_recordingDuration),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_recordingPath != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Recording...',
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2),
                        color: AppColors.slate500,
                        onPressed: () => _stopRecording(cancel: true),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.send),
                        color: AppColors.primary,
                        onPressed: () => _stopRecording(cancel: false),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _remarkController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mic Button (Always visible when not recording)
                      CircleAvatar(
                        backgroundColor: AppColors.slate100,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.mic,
                            color: AppColors.slate700,
                            size: 20,
                          ),
                          onPressed: _startRecording,
                        ),
                      ),
                      // Send Button (Visible only when text is typed)
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _remarkController,
                        builder: (context, value, _) {
                          if (value.text.trim().isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: IconButton(
                                  icon: const Icon(
                                    LucideIcons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _submitRemark(),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RemarkCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> remark;
  final String? agentId;
  final bool isMe;

  const _RemarkCard({
    required this.remark,
    required this.agentId,
    required this.isMe,
  });

  @override
  ConsumerState<_RemarkCard> createState() => _RemarkCardState();
}

class _RemarkCardState extends ConsumerState<_RemarkCard> {
  @override
  Widget build(BuildContext context) {
    final agentAsync = widget.agentId != null
        ? ref.watch(ticketAssignedAgentProvider(widget.agentId!))
        : null;
    final _rawTs = widget.remark['created_at'] as String;
    final _normalized = (_rawTs.endsWith('Z') || _rawTs.contains('+'))
        ? _rawTs
        : '${_rawTs}Z';
    final createdAt = DateTime.parse(_normalized).toUtc();
    final remarkType = widget.remark['remark_type'] as String? ?? 'text';

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: widget.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: widget.isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isMe) ...[
              if (agentAsync != null)
                agentAsync.when(
                  data: (agent) => Text(
                    agent?['username'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.primary,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                )
              else
                Text(
                  'Customer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 4),
            ],
            if (remarkType == 'voice')
              VoiceNoteWidget(
                voiceUrl: widget.remark['voice_url'] as String? ?? '',
                duration: widget.remark['duration_seconds'] as int? ?? 0,
                isMe: widget.isMe,
              )
            else
              Text(
                widget.remark['remark'] as String? ?? '',
                style: TextStyle(
                  color: widget.isMe ? Colors.white : AppColors.slate900,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeago.format(createdAt.toLocal(), locale: 'en_short'),
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.slate400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
