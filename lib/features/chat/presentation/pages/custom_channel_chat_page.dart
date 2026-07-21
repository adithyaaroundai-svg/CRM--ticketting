import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/custom_channel_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/custom_channel.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/markdown_text_editing_controller.dart';

IconData _getFileIcon(String? fileType) {
  if (fileType == null) return Icons.insert_drive_file;
  
  final type = fileType.toLowerCase();
  if (type == 'pdf') return Icons.picture_as_pdf;
  if (type == 'jpg' || type == 'jpeg' || type == 'png' || type == 'gif') return Icons.image;
  if (type == 'mp4' || type == 'mov' || type == 'avi') return Icons.videocam;
  if (type == 'mp3' || type == 'wav') return Icons.audio_file;
  if (type == 'doc' || type == 'docx') return Icons.description;
  if (type == 'xls' || type == 'xlsx') return Icons.table_chart;
  if (type == 'zip' || type == 'rar') return Icons.folder_zip;
  
  return Icons.insert_drive_file;
}

class CustomChannelChatPage extends ConsumerStatefulWidget {
  final String channelId;

  const CustomChannelChatPage({super.key, required this.channelId});

  @override
  ConsumerState<CustomChannelChatPage> createState() => _CustomChannelChatPageState();
}

class _CustomChannelChatPageState extends ConsumerState<CustomChannelChatPage> {
  final MarkdownTextEditingController _messageCtrl = MarkdownTextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showScrollToBottom = false;
  String? _replyingTo;
  String? _replyToName;
  String? _replyToContent;

  // File attachment state
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  // Emoji / GIF picker state
  bool _showEmojiPicker = false;
  bool _showGifPicker = false;
  final List<Map<String, String>> _gifResults = [];
  bool _gifLoading = false;
  final _gifSearchCtrl = TextEditingController();

  // Mentions
  bool _showMentions = false;
  String _mentionQuery = '';
  int _mentionStartIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);

    _messageCtrl.addListener(() {
      final text = _messageCtrl.text;
      final selection = _messageCtrl.selection;
      
      if (!selection.isValid || selection.baseOffset == -1) return;

      final cursorPos = selection.baseOffset;
      final textBeforeCursor = text.substring(0, cursorPos);
      final lastAtSignIndex = textBeforeCursor.lastIndexOf('@');

      if (lastAtSignIndex != -1) {
        final textAfterAtSign = textBeforeCursor.substring(lastAtSignIndex + 1);
        if (!textAfterAtSign.contains(' ')) {
          setState(() {
            _showMentions = true;
            _mentionQuery = textAfterAtSign.toLowerCase();
            _mentionStartIndex = lastAtSignIndex;
          });
          return;
        }
      }
      
      if (_showMentions) {
        setState(() {
          _showMentions = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _gifSearchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final currentScroll = _scrollCtrl.position.pixels;
    final shouldShow = currentScroll > 100;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setReply(ChatMessage message) {
    setState(() {
      _replyingTo = message.id;
      _replyToName = message.senderName;
      _replyToContent = message.content;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _replyToName = null;
      _replyToContent = null;
    });
  }

  // Hardcoded working GIFs from Giphy public CDN — verified working URLs
  static const _defaultGifs = [
    'https://media.giphy.com/media/ZqlvCTNHpqrio/giphy.gif',
    'https://media.giphy.com/media/du3J3cXyzhj75IOgvA/giphy.gif',
    'https://media.giphy.com/media/3oEjI6SIIHBdRxXI40/giphy.gif',
    'https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif',
    'https://media.giphy.com/media/26ufdipQqU2lhNA4g/giphy.gif',
    'https://media.giphy.com/media/xT9IgG50Lg7rusyOqY/giphy.gif',
    'https://media.giphy.com/media/11sBLVxNs7v6WA/giphy.gif',
    'https://media.giphy.com/media/5GoVLqeAOo6PK/giphy.gif',
    'https://media.giphy.com/media/l3q2K5jinAlChoCLS/giphy.gif',
    'https://media.giphy.com/media/26BRuo6sLetdllPAQ/giphy.gif',
    'https://media.giphy.com/media/3oEdv9Y3FVGw5HKgGY/giphy.gif',
    'https://media.giphy.com/media/xT9IgDECMFdlRxetDO/giphy.gif',
  ];

  Future<void> _searchGifs(String query) async {
    if (query.trim().isEmpty || query == 'trending') {
      setState(() {
        _gifResults.clear();
        _gifResults.addAll(_defaultGifs.map((url) => {'url': url, 'preview': url}));
        _gifLoading = false;
      });
      return;
    }
    setState(() => _gifLoading = true);
    try {
      final uri = Uri.parse(
        'https://tenor.googleapis.com/v2/search?q=${Uri.encodeComponent(query)}&key=AIzaSyAyimkuYQYF_FXVql9aozqBPHzMKADCQNQ&limit=12&media_filter=gif',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = (data['results'] as List).map<Map<String, String>>((r) {
          final url = r['media_formats']?['gif']?['url'] as String? ?? '';
          final preview = r['media_formats']?['tinygif']?['url'] as String? ?? url;
          return {'url': url, 'preview': preview};
        }).where((m) => m['url']!.isNotEmpty).toList();
        if (results.isNotEmpty) {
          setState(() {
            _gifResults.clear();
            _gifResults.addAll(results);
          });
          setState(() => _gifLoading = false);
          return;
        }
      }
    } catch (_) {}
    setState(() {
      _gifResults.clear();
      _gifResults.addAll(_defaultGifs.map((url) => {'url': url, 'preview': url}));
      _gifLoading = false;
    });
  }

  Future<void> _sendGif(String gifUrl) async {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;
    setState(() => _showGifPicker = false);
    final controller = ref.read(chatControllerProvider.notifier);
    await controller.sendMessage(
      senderId: currentUser.id,
      senderName: currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.username,
      senderRole: currentUser.role,
      content: '',
      fileUrl: gifUrl,
      fileName: 'gif',
      fileType: 'gif',
      channel: widget.channelId,
    );
    _scrollToBottom();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  void _cancelFileSelection() {
    setState(() {
      _selectedFile = null;
    });
  }

  Color _userColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
      AppColors.info,
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildMentionsList() {
    final agentsAsync = ref.watch(agentsListProvider);

    return agentsAsync.when(
      data: (agents) {
        final filteredAgents = agents.where((a) {
          final name = (a['full_name'] ?? a['username'] ?? '').toString().toLowerCase();
          final role = (a['role'] ?? '').toString().toLowerCase();
          return name.contains(_mentionQuery) || role.contains(_mentionQuery);
        }).toList()
          ..sort((a, b) {
            final nameA = (a['full_name'] ?? a['username'] ?? '').toString().toLowerCase();
            final nameB = (b['full_name'] ?? b['username'] ?? '').toString().toLowerCase();
            return nameA.compareTo(nameB);
          });

        if (filteredAgents.isEmpty) return const SizedBox.shrink();

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: filteredAgents.length,
            itemBuilder: (context, index) {
              final agent = filteredAgents[index];
              final name = (agent['full_name'] ?? agent['username'] ?? '').toString();
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: _userColor(name).withValues(alpha: 0.15),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 10,
                      color: _userColor(name),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _userColor(name),
                  ),
                ),
                subtitle: Text(
                  (agent['role'] ?? '').toString(),
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => _insertMention(name),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _insertMention(String name) {
    final text = _messageCtrl.text;
    final newText = text.replaceRange(
      _mentionStartIndex,
      _messageCtrl.selection.baseOffset,
      '@$name ',
    );

    _messageCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _mentionStartIndex + name.length + 2,
      ),
    );

    setState(() {
      _showMentions = false;
    });

    _focusNode.requestFocus();
  }

  void _triggerMention() {
    final text = _messageCtrl.text;
    final selection = _messageCtrl.selection;
    
    int insertOffset = selection.baseOffset;
    if (insertOffset == -1) {
      insertOffset = text.length;
    }
    
    String prefix = '@';
    if (insertOffset > 0 && text[insertOffset - 1] != ' ') {
      prefix = ' @';
    }
    
    final newText = text.replaceRange(insertOffset, insertOffset, prefix);
    
    _messageCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertOffset + prefix.length),
    );
    
    setState(() {
      _showMentions = true;
      _mentionQuery = '';
      _mentionStartIndex = insertOffset + (prefix.length - 1);
    });
    
    _focusNode.requestFocus();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    _messageCtrl.clear();
    _focusNode.unfocus();

    String? fileUrl;
    String? fileName;
    String? fileType;

    // Upload file if selected
    if (_selectedFile != null) {
      setState(() => _isUploading = true);
      try {
        final supabase = Supabase.instance.client;
        final filePath = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
        
        Uint8List fileBytes;
        if (_selectedFile!.bytes != null) {
          fileBytes = Uint8List.fromList(_selectedFile!.bytes!);
        } else if (_selectedFile!.path != null) {
          fileBytes = await File(_selectedFile!.path!).readAsBytes();
        } else {
          throw Exception('No file bytes or path available');
        }
        
        await supabase.storage
            .from('chat_attachments')
            .uploadBinary(
              filePath, 
              fileBytes,
              fileOptions: FileOptions(
                contentType: _getMimeType(_selectedFile!.extension),
                upsert: false,
              ),
            );

        fileUrl = supabase.storage.from('chat_attachments').getPublicUrl(filePath);
        fileName = _selectedFile!.name;
        fileType = _selectedFile!.extension;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload file: $e')),
          );
        }
        setState(() => _isUploading = false);
        return;
      }
      setState(() {
        _selectedFile = null;
        _isUploading = false;
      });
    }

    final controller = ref.read(chatControllerProvider.notifier);
    await controller.sendMessage(
      senderId: currentUser.id,
      senderName: currentUser.fullName.isNotEmpty ? currentUser.fullName : currentUser.username,
      senderRole: currentUser.role,
      content: text,
      replyToMessageId: _replyingTo,
      replyToSenderName: _replyToName,
      replyToContent: _replyToContent,
      fileUrl: fileUrl,
      fileName: fileName,
      fileType: fileType,
      channel: widget.channelId,
    );

    setState(() {
      _replyingTo = null;
      _replyToName = null;
      _replyToContent = null;
    });

    _scrollToBottom();
  }

  String _getMimeType(String? extension) {
    if (extension == null) return 'application/octet-stream';
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip': return 'application/zip';
      case 'rar': return 'application/vnd.rar';
      default: return 'application/octet-stream';
    }
  }

  Future<void> _launchGroupTeamsCall(CustomChannel channel, {required bool video}) async {
    final agentsAsync = ref.read(agentsListProvider);
    final agents = agentsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <Map<String, dynamic>>[],
    );

    final currentUser = ref.read(authProvider);

    final List<String> teamsIds = [];
    
    for (final memberId in channel.memberIds) {
      print('Checking member: $memberId');
      if (memberId == currentUser?.id) {
        print('Skipping current user');
        continue; // Skip the current user themselves
      }
      
      final agentData = agents.firstWhere(
        (a) => a['id']?.toString() == memberId,
        orElse: () => <String, dynamic>{},
      );
      
      print('Found agentData: $agentData');
      
      final teamsId = agentData['teams_user_id'] as String?;
      print('Teams ID for $memberId is: $teamsId');
      if (teamsId != null && teamsId.trim().isNotEmpty) {
        teamsIds.add(teamsId.trim());
      }
    }

    if (teamsIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('None of the channel members have a Microsoft Teams ID set.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final encoded = Uri.encodeComponent(teamsIds.join(','));
    final url = video
        ? 'https://teams.microsoft.com/l/call/0/0?users=$encoded&withVideo=true'
        : 'https://teams.microsoft.com/l/call/0/0?users=$encoded';

    final uri = Uri.parse(url);
    try {
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Microsoft Teams. Please make sure it is installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChannelDetailsDialog(CustomChannel channel, List<ChatMessage>? messages) {
    final agentsAsync = ref.read(agentsListProvider);
    final agents = agentsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <Map<String, dynamic>>[],
    );

    final members = channel.memberIds.map((id) {
      final agent = agents.firstWhere(
        (a) => a['id']?.toString() == id,
        orElse: () => <String, dynamic>{},
      );
      final name = agent['full_name'] as String? ?? agent['username'] as String? ?? 'Unknown User';
      final role = agent['role'] as String? ?? '';
      return {'id': id, 'name': name, 'role': role};
    }).toList();

    final mediaMessages = messages?.where((m) => m.fileUrl != null && !m.isDeleted).toList() ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.slate900),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Channel Info',
                style: TextStyle(
                  color: AppColors.slate900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withAlpha(26),
                          child: Icon(
                            channel.isPrivate ? LucideIcons.lock : LucideIcons.hash,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          channel.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created on ${DateFormat('MMM d, yyyy').format(channel.createdAt.toLocal())}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Media Section
                  if (mediaMessages.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Media, links, and docs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate800,
                                ),
                              ),
                              Text(
                                '${mediaMessages.length}',
                                style: const TextStyle(color: AppColors.slate500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: mediaMessages.length,
                              itemBuilder: (context, index) {
                                final msg = mediaMessages[index];
                                final isImage = msg.fileType == 'jpg' || msg.fileType == 'jpeg' || msg.fileType == 'png' || msg.fileType == 'gif';
                                
                                return GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse(msg.fileUrl!);
                                    try {
                                      await url_launcher.launchUrl(
                                        uri,
                                        mode: url_launcher.LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint('Could not launch ${msg.fileUrl}: $e');
                                    }
                                  },
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: isImage
                                      ? Image.network(
                                          msg.fileUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(_getFileIcon(msg.fileType), color: AppColors.slate500, size: 28),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                msg.fileName ?? 'File',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 10, color: AppColors.slate600),
                                              ),
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
                    const SizedBox(height: 8),
                  ],
                  
                  // Members Section
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${members.length} Members',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withAlpha(26),
                                child: Text(
                                  (member['name'] as String)[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                member['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: (member['role'] as String).isNotEmpty
                                ? Text(
                                    member['role'] as String,
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                                  )
                                : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to messages for THIS channel ID
    final messagesAsync = ref.watch(chatStreamProvider(widget.channelId));
    final currentUser = ref.watch(authProvider);
    final channelsAsync = ref.watch(customChannelsProvider);

    // Find channel metadata
    CustomChannel? channel;
    if (channelsAsync.hasValue) {
      try {
        channel = channelsAsync.value!.firstWhere((c) => c.id == widget.channelId);
      } catch (_) {}
    }

    ref.listen(chatStreamProvider(widget.channelId), (previous, next) {
      if (next is AsyncData<List<ChatMessage>> && next.value.isNotEmpty) {
        final previousCount = previous is AsyncData<List<ChatMessage>> ? previous.value.length : 0;
        final currentCount = next.value.length;
        if (currentCount > previousCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.jumpTo(0.0);
            }
          });
        }
      }
    });

    return MainLayout(
      currentPath: '/c/${widget.channelId}',
      child: Scaffold(
        backgroundColor: context.isDarkMode ? context.adaptiveBackground : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: InkWell(
            onTap: channel != null ? () => _showChannelDetailsDialog(channel!, messagesAsync.value) : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        channel?.isPrivate == true ? LucideIcons.lock : LucideIcons.hash,
                        size: 18,
                        color: context.adaptiveSlate900,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        channel?.name ?? 'Loading...',
                        style: TextStyle(
                          color: context.adaptiveSlate900,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (channel != null)
                    Text(
                      channel.isPrivate ? 'Private Channel' : 'Public Channel',
                      style: TextStyle(
                        color: context.adaptiveSlate500,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ),
          backgroundColor: context.isDarkMode ? context.adaptiveCard : Colors.white,
          elevation: 0,
          actions: [
            if (channel != null) ...[
              Tooltip(
                message: 'Group Audio Call (Teams)',
                child: InkWell(
                  onTap: () => _launchGroupTeamsCall(channel!, video: false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Icon(LucideIcons.phone, size: 18, color: Colors.green.shade700),
                  ),
                ),
              ),
              Tooltip(
                message: 'Group Video Call (Teams)',
                child: InkWell(
                  onTap: () => _launchGroupTeamsCall(channel!, video: true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Icon(LucideIcons.video, size: 18, color: Colors.green.shade700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ]
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.hash,
                            size: 48,
                            color: AppColors.slate300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No messages yet',
                            style: TextStyle(
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Start the conversation!',
                            style: TextStyle(
                              color: AppColors.slate400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, rawIndex) {
                          final index = messages.length - 1 - rawIndex;
                          final msg = messages[index];
                          final isMe = msg.senderId == currentUser?.id;
                          final prevMsg = index > 0 ? messages[index - 1] : null;
                          final showSender = prevMsg == null || prevMsg.senderId != msg.senderId;
                          final isDeleted = msg.isDeleted;

                          return _ChatBubble(
                            message: msg,
                            isMe: isMe,
                            showSender: showSender,
                            isDeleted: isDeleted,
                            onReply: () => _setReply(msg),
                          );
                        },
                      ),
                      if (_showScrollToBottom)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton.small(
                            onPressed: _scrollToBottom,
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.arrow_downward, color: Colors.white),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error: $err'),
                ),
              ),
            ),
            // Reply preview
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.reply, size: 16, color: AppColors.slate500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to $_replyToName',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _replyToContent ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _cancelReply,
                    ),
                  ],
                ),
              ),
            // File preview
            if (_selectedFile != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Icon(_getFileIcon(_selectedFile!.extension), size: 20, color: AppColors.slate500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (_isUploading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _cancelFileSelection,
                      ),
                  ],
                ),
              ),
            // Emoji picker panel
            if (_showEmojiPicker)
              Container(
                height: 220,
                color: context.isDarkMode ? context.adaptiveCard : Colors.white,
                padding: const EdgeInsets.all(8),
                child: GridView.count(
                  crossAxisCount: 10,
                  children: [
                    '😀','😂','😍','🥰','😎','🤔','😢','😡','🎉','🔥',
                    '👍','👎','❤️','💯','✅','🙏','😊','🤣','😅','😭',
                    '🤩','😏','😒','🤗','😤','🥺','😇','🤪','😜','🫡',
                    '👋','🙌','👏','🤝','✌️','🤞','💪','🫶','🫂','👀',
                    '🚀','⭐','🌟','💡','🎯','🏆','💎','🌈','🍕','☕',
                  ].map((e) => GestureDetector(
                    onTap: () {
                      _messageCtrl.text += e;
                      _messageCtrl.selection = TextSelection.collapsed(offset: _messageCtrl.text.length);
                    },
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  )).toList(),
                ),
              ),
            // GIF picker panel
            if (_showGifPicker)
              Container(
                height: 260,
                color: context.isDarkMode ? context.adaptiveCard : Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: _gifSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search GIFs...',
                          filled: true,
                          fillColor: context.isDarkMode ? context.adaptiveBackground : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, size: 18),
                            onPressed: () => _searchGifs(_gifSearchCtrl.text),
                          ),
                        ),
                        onSubmitted: _searchGifs,
                      ),
                    ),
                    Expanded(
                      child: _gifLoading
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _gifResults.isEmpty
                              ? const Center(child: Text('Search for GIFs above', style: TextStyle(color: AppColors.slate400)))
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                    childAspectRatio: 1.5,
                                  ),
                                  itemCount: _gifResults.length,
                                  itemBuilder: (_, i) => GestureDetector(
                                    onTap: () => _sendGif(_gifResults[i]['url']!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        _gifResults[i]['preview']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                      ),
                                    ),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            // Mentions List
            if (_showMentions) _buildMentionsList(),
            
            // Selected File Preview
            if (_selectedFile != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? context.adaptiveCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.isDarkMode ? context.adaptiveSlate800 : Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_getFileIcon(_selectedFile!.extension), size: 32, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedFile!.size > 0)
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(fontSize: 12, color: context.adaptiveSlate500),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.adaptiveSlate500),
                      onPressed: () => setState(() => _selectedFile = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            
            // Input area
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: MediaQuery.sizeOf(context).width < 800 ? 0 : 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Attach file button
                    IconButton(
                      icon: Icon(Icons.add, color: context.adaptiveSlate500),
                      onPressed: _pickFile,
                      padding: const EdgeInsets.all(12),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? context.adaptiveCard : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.isDarkMode ? context.adaptiveSlate800 : AppColors.slate200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey == LogicalKeyboardKey.enter &&
                                      !HardwareKeyboard.instance.isShiftPressed) {
                                    _sendMessage();
                                  }
                                },
                                child: TextField(
                                  controller: _messageCtrl,
                                  focusNode: _focusNode,
                                  maxLines: MediaQuery.sizeOf(context).width < 800 ? 1 : 5,
                                  minLines: 1,
                                  textInputAction: TextInputAction.newline,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.isDarkMode ? Colors.white : AppColors.slate900,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: context.adaptiveSlate400, fontSize: 14),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: MediaQuery.sizeOf(context).width < 800 ? 0 : 12,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(),
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 12.0, right: 4.0),
                                      child: InkWell(
                                        onTap: () => setState(() {
                                          _showEmojiPicker = !_showEmojiPicker;
                                          if (_showEmojiPicker) _showGifPicker = false;
                                        }),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.emoji_emotions_outlined,
                                            color: _showEmojiPicker ? AppColors.primary : context.adaptiveSlate500,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 12.0, left: 4.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: _triggerMention,
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Icon(Icons.alternate_email, color: context.adaptiveSlate500, size: 20),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => setState(() {
                                              _showGifPicker = !_showGifPicker;
                                              if (_showGifPicker) {
                                                _showEmojiPicker = false;
                                                if (_gifResults.isEmpty) _searchGifs('trending');
                                              }
                                            }),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: Icon(
                                                Icons.movie_outlined,
                                                color: _showGifPicker ? AppColors.primary : context.adaptiveSlate500,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  onTap: () => setState(() {
                                    _showEmojiPicker = false;
                                    _showGifPicker = false;
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send button
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                        onPressed: _sendMessage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Derives a consistent, vibrant color from a sender's name string.
Color _senderColor(String name) {
  const colors = [
    Color(0xFF6366F1), // indigo
    Color(0xFF0EA5E9), // sky
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
    Color(0xFFF97316), // orange
    Color(0xFF06B6D4), // cyan
    Color(0xFFA855F7), // purple
    Color(0xFF84CC16), // lime
  ];
  int hash = 0;
  for (final c in name.codeUnits) {
    hash = (hash * 31 + c) & 0x7FFFFFFF;
  }
  return colors[hash % colors.length];
}

class _ChatBubble extends ConsumerStatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSender;
  final bool isDeleted;
  final VoidCallback onReply;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.showSender,
    required this.isDeleted,
    required this.onReply,
  });

  @override
  ConsumerState<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends ConsumerState<_ChatBubble> {
  bool _hovered = false;

  void _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be marked as deleted for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(chatControllerProvider.notifier).deleteMessage(widget.message.id);
    }
  }

  void _sendReaction(String emoji) {
    setState(() => _hovered = false);
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;
    ref.read(chatControllerProvider.notifier).toggleReaction(
      messageId: widget.message.id,
      userId: currentUser.id,
      emoji: emoji,
    );
  }

  void _showAllReactions(BuildContext context) {
    setState(() => _hovered = false);
    const all = [
      '👍','👎','❤️','😂','😮','😢','','',
      '👏','🎉','🙏','💯','✅','🤔','😊','🥰',
      '😎','🤩','😭','🤣','😅','🫡','💪','🚀',
      '⭐','🌟','💡','🎯','🏆','💎','🌈','🍕',
    ];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Reaction',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: all.map((e) => GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendReaction(e);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  )).toList(),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = widget.isMe;
    final showSender = widget.showSender;
    final isDeleted = widget.isDeleted;
    final nameColor = _senderColor(message.senderName ?? 'User');
    final timeStr = message.createdAt != null 
      ? "${message.createdAt.toLocal().hour}:${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}"
      : "";

    // Call activity messages — rendered as centered notification cards
    if (message.content.startsWith('__CALL_') && !isDeleted) {
      return _CallActivityCard(content: message.content, createdAt: message.createdAt);
    }

    return TapRegion(
      onTapOutside: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onLongPress: () {
          final isMobile = MediaQuery.of(context).size.width < 900;
          if (isMobile) {
            setState(() => _hovered = true);
          }
        },
        onTap: () {
          final isMobile = MediaQuery.of(context).size.width < 900;
          if (isMobile && _hovered) {
            setState(() => _hovered = false);
          }
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
        child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Constrain bubble to max 75% of available width
            ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Always show sender name
                    if (showSender && message.senderName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          message.senderName!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: nameColor,
                          ),
                        ),
                      ),
                    // Bubble shrinks to content
                    IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.replyToMessageId != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? (context.isDarkMode
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : Colors.white)
                                      : (context.isDarkMode
                                            ? Colors.black.withValues(alpha: 0.2)
                                            : Colors.black.withValues(alpha: 0.04)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.replyToSenderName ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                        color: isMe
                                            ? (context.isDarkMode ? Colors.white.withValues(alpha: 0.9) : AppColors.primary)
                                            : AppColors.slate600,
                                      ),
                                    ),
                                    Text(
                                      message.replyToContent ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? (context.isDarkMode ? Colors.white70 : AppColors.primary.withValues(alpha: 0.8))
                                            : AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Message text + time on the same row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: isDeleted
                                      ? Text(
                                          'This message was deleted',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.slate400,
                                          ),
                                        )
                                      : Text(
                                          message.content,
                                          style: TextStyle(
                                            color: isMe
                                                ? (context.isDarkMode ? Colors.white : AppColors.primary)
                                                : (context.isDarkMode ? Colors.white : AppColors.slate800),
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? (context.isDarkMode ? Colors.white60 : AppColors.primary.withValues(alpha: 0.6))
                                        : (context.isDarkMode ? Colors.white54 : AppColors.slate400),
                                  ),
                                ),
                              ],
                            ),
                            if (message.fileUrl != null && !isDeleted)
                              if (message.fileType?.toLowerCase() == 'gif')
                                // Render GIF as animated inline image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    message.fileUrl!,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (_, child, progress) => progress == null
                                        ? child
                                        : SizedBox(
                                            width: 200,
                                            height: 120,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          ),
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 200,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(child: Icon(Icons.gif, size: 32, color: AppColors.slate400)),
                                    ),
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse(message.fileUrl!);
                                    try {
                                      await url_launcher.launchUrl(
                                        uri,
                                        mode: url_launcher.LaunchMode.externalApplication,
                                      );
                                    } catch (e) {
                                      debugPrint('Could not launch ${message.fileUrl}: $e');
                                    }
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getFileIcon(message.fileType),
                                            size: 16, color: AppColors.slate500),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            message.fileName ?? 'File',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(LucideIcons.download,
                                            size: 14, color: AppColors.slate500),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    // Reaction badges below bubble
                    if (widget.message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: () {
                            final grouped = <String, int>{};
                            for (final r in widget.message.reactions) {
                              final e = r['emoji'] as String? ?? '';
                              if (e.isNotEmpty) grouped[e] = (grouped[e] ?? 0) + 1;
                            }
                            return grouped.entries.map((entry) => GestureDetector(
                              onTap: () => _sendReaction(entry.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3)],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 3),
                                    Text('${entry.value}', style: const TextStyle(fontSize: 11, color: AppColors.slate600, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            )).toList();
                          }(),
                        ),
                      ),
                  ],
                ),
              ),
            // Hover action bar
            if (_hovered && !isDeleted) ...[
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick reactions
                    for (final emoji in ['👍', '❤️', '😂', '😮', '😢'])
                      GestureDetector(
                        onTap: () => _sendReaction(emoji),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(emoji, style: const TextStyle(fontSize: 18)),
                        ),
                      ),
                    // More reactions
                    Tooltip(
                      message: 'More reactions',
                      child: InkWell(
                        onTap: () => _showAllReactions(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(Icons.add, size: 16, color: AppColors.slate500),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 18, color: AppColors.slate200, margin: const EdgeInsets.symmetric(horizontal: 4)),
                    // Reply
                    _ActionBtn(icon: Icons.reply, tooltip: 'Reply', onTap: widget.onReply),
                    // Delete (own messages only)
                    if (isMe)
                      _ActionBtn(icon: Icons.delete_outline, tooltip: 'Delete', color: Colors.red, onTap: () => _delete(context)),
                  ],
                ),
              ),
            ],
          ],
        ),
        ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color ?? AppColors.slate500),
        ),
      ),
    );
  }
}

// ── Call Activity Card ────────────────────────────────────────────────────────
class _CallActivityCard extends StatelessWidget {
  final String content;
  final DateTime createdAt;

  const _CallActivityCard({required this.content, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final info = _parseCallContent(content);
    final timeStr = DateFormat('h:mm a').format(createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: info.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: info.color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(info.icon, size: 16, color: info.color),
              const SizedBox(width: 8),
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: info.color,
                ),
              ),
              if (info.duration != null) ...[
                Text(
                  ' · ${info.duration}',
                  style: TextStyle(fontSize: 12, color: info.color.withValues(alpha: 0.7)),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                timeStr,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _CallInfo _parseCallContent(String content) {
    final isVideo = content.contains('_VIDEO_');
    String? duration;
    final colonIdx = content.lastIndexOf(':');
    if (colonIdx != -1 && colonIdx < content.length - 1 && !content.substring(colonIdx + 1).startsWith('//')) {
      duration = content.substring(colonIdx + 1).trim();
      if (duration.isEmpty) duration = null;
    }
    if (content.contains('_MISSED__')) {
      return _CallInfo(icon: isVideo ? LucideIcons.videoOff : LucideIcons.phoneOff, label: isVideo ? 'Missed Video Call' : 'Missed Audio Call', color: Colors.red.shade600, duration: duration);
    } else if (content.contains('_ENDED__')) {
      return _CallInfo(icon: isVideo ? LucideIcons.video : LucideIcons.phone, label: isVideo ? 'Video Call Ended' : 'Audio Call Ended', color: Colors.grey.shade600, duration: duration);
    } else if (content.contains('_ONGOING__')) {
      return _CallInfo(icon: isVideo ? LucideIcons.video : LucideIcons.phone, label: isVideo ? 'Video Call Ongoing' : 'Audio Call Ongoing', color: Colors.green.shade600, duration: duration);
    } else {
      return _CallInfo(icon: isVideo ? LucideIcons.video : LucideIcons.phone, label: isVideo ? 'Video Call Started' : 'You were in a huddle', color: const Color(0xFF2563EB), duration: duration);
    }
  }
}

class _CallInfo {
  final IconData icon;
  final String label;
  final Color color;
  final String? duration;
  const _CallInfo({required this.icon, required this.label, required this.color, this.duration});
}

