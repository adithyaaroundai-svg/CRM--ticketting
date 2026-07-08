import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:intl/intl.dart';

import 'package:file_picker/file_picker.dart';

import 'package:url_launcher/url_launcher.dart' as url_launcher;



import '../../../../core/design_system/design_system.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../providers/chat_provider.dart';

import '../../domain/entities/chat_message.dart';

import '../../data/repositories/chat_repository.dart';

import '../../../tickets/domain/entities/ticket.dart';

import '../../../tickets/presentation/providers/ticket_provider.dart';

import '../../../dashboard/presentation/widgets/create_ticket_dialog.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
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

Future<void> _downloadFile(String url, String fileName) async {
  try {
    await url_launcher.launchUrl(Uri.parse(url));
  } catch (e) {
    // Handle error
  }
}

class DirectMessagePage extends ConsumerStatefulWidget {
  final String partnerId;

  const DirectMessagePage({super.key, required this.partnerId});

  @override
  ConsumerState<DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends ConsumerState<DirectMessagePage> {

  final MarkdownTextEditingController _textCtrl = MarkdownTextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  final ScrollController _scrollCtrl = ScrollController();

  Timer? _autoRefreshTimer;

  bool _showMentions = false;

  String _mentionQuery = '';

  int _mentionStartIndex = -1;

  String? _entryFirstUnreadMessageId;
  bool _capturedEntryUnread = false;
  bool _initialReadMarked = false;

  DateTime? _lastMarkedReadAt;

  bool _showFormattingBar = false;

  final GlobalKey _unreadKey = GlobalKey();

  bool _hasInitialScrolled = false;
  ChatMessage? _replyingToMessage;
  PlatformFile? _selectedFile;
  bool _isUploadingFile = false;

  void _insertFormatting(String prefix, String suffix) {
    final text = _textCtrl.text;
    final selection = _textCtrl.selection;
    if (selection.baseOffset == -1) {
      _textCtrl.text = '$text$prefix$suffix';
      _textCtrl.selection = TextSelection.collapsed(offset: _textCtrl.text.length - suffix.length);
      return;
    }
    
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
    
    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.start + prefix.length + selectedText.length,
      ),
    );
    _messageFocusNode.requestFocus();
  }

  /// Prefixes each selected line (or inserts a template if nothing selected).
  void _insertList({required bool ordered}) {
    final text = _textCtrl.text;
    final selection = _textCtrl.selection;

    // No selection — insert a 3-item template at cursor
    if (selection.baseOffset == -1 || selection.start == selection.end) {
      final cursor = selection.baseOffset == -1 ? text.length : selection.start;
      final needsNewline = cursor > 0 && text[cursor - 1] != '\n';
      final template = ordered ? '${needsNewline ? '\n' : ''}1. \n2. \n3. ' : '${needsNewline ? '\n' : ''}- \n- \n- ';
      final newText = text.replaceRange(cursor, cursor, template);
      _textCtrl.value = TextEditingValue(
        text: newText,
        // Place cursor after the first bullet
        selection: TextSelection.collapsed(offset: cursor + (needsNewline ? 1 : 0) + (ordered ? 3 : 2)),
      );
      _messageFocusNode.requestFocus();
      return;
    }

    // Selection — prefix each line in the selection
    final selectedText = text.substring(selection.start, selection.end);
    final lines = selectedText.split('\n');
    final numberedLines = lines.asMap().entries.map((e) {
      final lineText = e.value;
      if (lineText.trim().isEmpty) return lineText;
      return ordered ? '${e.key + 1}. $lineText' : '- $lineText';
    }).join('\n');

    final newText = text.replaceRange(selection.start, selection.end, numberedLines);
    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + numberedLines.length,
      ),
    );
    _messageFocusNode.requestFocus();
  }

  Widget _buildFormattingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _formatBtn(Icons.format_bold, 'Bold', '**', '**'),
            _formatBtn(Icons.format_italic, 'Italic', '_', '_'),
            _formatBtn(Icons.format_underline, 'Underline', '<u>', '</u>'),
            _formatBtn(Icons.format_strikethrough, 'Strikethrough', '~~', '~~'),
            Container(width: 1, height: 16, color: AppColors.slate300, margin: const EdgeInsets.symmetric(horizontal: 8)),
            _formatBtn(Icons.link, 'Link', '[', '](url)'),
            Tooltip(
              message: 'Ordered List',
              child: InkWell(
                onTap: () => _insertList(ordered: true),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.format_list_numbered, size: 18, color: AppColors.slate600),
                ),
              ),
            ),
            Tooltip(
              message: 'Bullet List',
              child: InkWell(
                onTap: () => _insertList(ordered: false),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.format_list_bulleted, size: 18, color: AppColors.slate600),
                ),
              ),
            ),
            _formatBtn(Icons.format_quote, 'Blockquote', '\n> ', ''),
            Container(width: 1, height: 16, color: AppColors.slate300, margin: const EdgeInsets.symmetric(horizontal: 8)),
            _formatBtn(Icons.code, 'Code', '`', '`'),
            _formatBtn(Icons.data_object, 'Code Block', '\n```\n', '\n```\n'),
          ],
        ),
      ),
    );
  }

  Widget _formatBtn(IconData icon, String tooltip, String prefix, String suffix) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _insertFormatting(prefix, suffix),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 18, color: AppColors.slate600),
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    // Preload read receipts cache for instant access
    ReadReceiptsTracker.preload();
    _textCtrl.addListener(_onTextChanged);

    // Mark conversation as read when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markConversationAsRead();
    });
  }



  void _onTextChanged() {

    final text = _textCtrl.text;

    final selection = _textCtrl.selection;

    if (selection.baseOffset == -1) return;



    final textBeforeCursor = text.substring(0, selection.baseOffset);

    final lastAtSignIndex = textBeforeCursor.lastIndexOf('@');



    if (lastAtSignIndex != -1) {

      if (lastAtSignIndex == 0 ||

          textBeforeCursor[lastAtSignIndex - 1] == ' ') {

        final query = textBeforeCursor.substring(lastAtSignIndex + 1);

        if (!query.contains(' ')) {

          setState(() {

            _showMentions = true;

            _mentionQuery = query.toLowerCase();

            _mentionStartIndex = lastAtSignIndex;

          });

          return;

        }

      }

    }



    if (_showMentions) {

      setState(() {

        _showMentions = false;

      });

    }

  }



  @override

  void dispose() {

    _textCtrl.dispose();
    _messageFocusNode.dispose();

    _scrollCtrl.dispose();

    _autoRefreshTimer?.cancel();

    super.dispose();

  }



  void _sendMessage() async {

    final plainText = _textCtrl.text.trim();

    if (plainText.isEmpty && _selectedFile == null) return;



    final agent = ref.read(authProvider);

    if (agent == null) return;

    String? fileUrl;
    String? fileName;
    String? fileType;

    if (_selectedFile != null) {
      setState(() {
        _isUploadingFile = true;
      });
      
      fileUrl = await _uploadFile(_selectedFile!);
      
      setState(() {
        _isUploadingFile = false;
      });
      
      if (fileUrl == null) {
        // Upload failed
        return;
      }
      fileName = _selectedFile!.name;
      fileType = _selectedFile!.extension;
    }

    ref

        .read(chatControllerProvider.notifier)

        .sendMessage(

          senderId: agent.id,

          senderName: agent.fullName,
          senderRole: agent.role,
          content: plainText,
          receiverId: widget.partnerId,
          senderAvatarUrl: agent.avatarUrl,
          replyToMessageId: _replyingToMessage?.id,
          replyToSenderName: _replyingToMessage?.senderName,
          replyToContent: _replyingToMessage?.content,
          fileUrl: fileUrl,
          fileName: fileName,
          fileType: fileType,
        );

    // Unread count is handled automatically by Postgres listener
    ref.invalidate(dmUnreadCountProvider(widget.partnerId));
    ref.invalidate(dmConversationsProvider);



    final agentsAsync = ref.read(agentsListProvider);

    final agents = agentsAsync.value ?? [];

    for (final a in agents) {

      final String fullName = a['full_name'] ?? a['username'] ?? '';

      if (fullName.isNotEmpty && plainText.contains('@$fullName')) {

        try {

          await Supabase.instance.client.from('notifications').insert({

            'user_id': a['id'],

            'type': 'mention',

            'title': 'Mentioned in Support',

            'message': '${agent.fullName} mentioned you: "$plainText"',

            'link': '/chat',

            'is_read': false,

          });

        } catch (_) {}

      }

    }



    _textCtrl.clear();

    setState(() {
      _replyingToMessage = null;
      _selectedFile = null;
      _showMentions = false;
    });

  }



  // ignore: unused_element
  Future<void> _showCreateTicketDialog() async {

    final createdTicket = await showDialog<Ticket>(

      context: context,

      builder: (context) => CreateTicketDialog(

        isSupport: false,
        postToChat: false,

      ),

    );



    if (createdTicket == null) return;

    await _sendCreatedTicketMessage(createdTicket);
    ref.invalidate(chatStreamProvider('support-chat'));
    ref.invalidate(chatUnreadCountProvider);
  }



  Future<void> _sendCreatedTicketMessage(Ticket ticket) async {

    final agent = ref.read(authProvider);

    if (agent == null) return;



    String companyName = 'Company';

    final customerData = await ref

        .read(ticketRepositoryProvider)

        .getCustomer(ticket.customerId);

    if (customerData != null) {

      final value = customerData['company_name']?.toString().trim();

      if (value != null && value.isNotEmpty) {

        companyName = value;

      }

    }



    final issue = (ticket.description?.trim().isNotEmpty == true)

        ? ticket.description!.trim()

        : ticket.title.trim();

    final content = [

      'Company: $companyName',

      'Issue: $issue',

      'TicketID: ${ticket.ticketId}',

    ].join('\n');



    await ref.read(chatRepositoryProvider).sendMessage(

          senderId: agent.id,

          senderName: agent.fullName,

          senderRole: agent.role,

          content: content,

        );

  }

  Future<void> _launchTeamsCall(String? teamsUserId, {required bool video}) async {
    if (teamsUserId == null || teamsUserId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This agent has not set up their Microsoft Teams ID yet.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final encoded = Uri.encodeComponent(teamsUserId.trim());
    final url = video
        ? 'https://teams.microsoft.com/l/call/0/0?users=$encoded&withVideo=true'
        : 'https://teams.microsoft.com/l/call/0/0?users=$encoded';

    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Microsoft Teams. Please make sure it is installed.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(dmStreamProvider(widget.partnerId));
    final currentUser = ref.watch(authProvider);
    
    if (!_initialReadMarked && messagesAsync.hasValue && messagesAsync.value!.isNotEmpty) {
      _initialReadMarked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markConversationAsRead();
      });
    }

    final agentsAsync = ref.watch(agentsListProvider);
    final partnerData = agentsAsync.maybeWhen(
      data: (agents) {
        final match = agents.firstWhere(
          (a) => a['id']?.toString() == widget.partnerId,
          orElse: () => <String, dynamic>{},
        );
        return match;
      },
      orElse: () => <String, dynamic>{},
    );
    final partnerName = (partnerData['full_name'] ?? partnerData['username'] ?? '').toString();
    final partnerAvatarUrl = partnerData['avatar_url'] as String?;
    final partnerTeamsId = partnerData['teams_user_id'] as String?;

    ref.listen(dmStreamProvider(widget.partnerId), (previous, next) {
      if (next is AsyncData<List<ChatMessage>> && next.value.isNotEmpty) {
        final previousCount = previous is AsyncData<List<ChatMessage>> ? previous.value.length : 0;
        final currentCount = next.value.length;

        if (currentCount > previousCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollCtrl.hasClients) {
              _scrollCtrl.jumpTo(
                _scrollCtrl.position.maxScrollExtent,
              );
            }
          });
        }

        // Mark as read whenever we are viewing this conversation
        final currentUser = ref.read(authProvider);
        if (currentUser != null && mounted) {
          final newest = next.value.last;
          if (newest.senderId != currentUser.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _markConversationAsRead();
            });
          }
        }
      }
    });

    return MainLayout(

      currentPath: '/chat',

      child: Scaffold(

        backgroundColor: const Color(0xFFF8FAFC),

        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/chat');
              }
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF1E293B),
            ),
          ),
          title: Row(
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  shape: BoxShape.circle,
                  image: partnerAvatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(partnerAvatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: partnerAvatarUrl == null
                    ? Center(
                        child: Text(
                          partnerName.isNotEmpty
                              ? partnerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null,
              ),
              // Name and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName.isNotEmpty ? partnerName : 'Direct Message',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      partnerName.isNotEmpty ? 'Direct Message' : 'Instant communication with the team',
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          backgroundColor: Colors.white,

          elevation: 0,

          actions: [

            // Audio Call button
            _CallButton(
              icon: LucideIcons.phone,
              tooltip: 'Audio Call via Teams',
              onTap: () => _launchTeamsCall(partnerTeamsId, video: false),
            ),

            // Video Call button
            _CallButton(
              icon: LucideIcons.video,
              tooltip: 'Video Call via Teams',
              onTap: () => _launchTeamsCall(partnerTeamsId, video: true),
            ),

            const SizedBox(width: 8),

          ],

          bottom: PreferredSize(

            preferredSize: const Size.fromHeight(1),

            child: Container(color: AppColors.slate200, height: 1),

          ),

        ),

        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
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
                                  LucideIcons.messageSquare,
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
                                  'Start the conversation with your team!',
                                  style: TextStyle(
                                    color: AppColors.slate400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (!_capturedEntryUnread && currentUser != null) {
                          _capturedEntryUnread = true;
                          _entryFirstUnreadMessageId = _findFirstUnreadMessageId(
                            messages,
                            currentUser.id,
                          );
                        }

                        if (!_hasInitialScrolled && messages.isNotEmpty) {
                          _hasInitialScrolled = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (_entryFirstUnreadMessageId != null && _unreadKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _unreadKey.currentContext!,
                                alignment: 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            } else if (_scrollCtrl.hasClients) {
                              _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                            }
                          });
                        }

                        _markVisibleMessagesRead(messages);

                        return ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          reverse: false,
                          physics: const ClampingScrollPhysics(),
                          itemCount: messages.length,
                          cacheExtent: 500,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg.senderId == currentUser?.id;
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final prevMsg = messages[index - 1];
                              if (!_isSameDay(msg.createdAt, prevMsg.createdAt)) {
                                showDateHeader = true;
                              }
                            }
                            final showUnreadLabel = msg.id == _entryFirstUnreadMessageId;
                            return Column(
                              children: [
                                if (showDateHeader) _DateHeader(date: msg.createdAt),
                                if (showUnreadLabel) _UnreadLabel(key: _unreadKey),
                                _ChatBubble(
                                  key: ValueKey(msg.id),
                                  message: msg,
                                  isMe: isMe,
                                  onDelete: () {
                                    _confirmDelete(context, msg.id);
                                  },
                                  onReply: () {
                                    _handleReply(msg);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                  if (_showMentions) _buildMentionsList(),
                  _buildInputArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {

    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  }



  void _markVisibleMessagesRead(List<ChatMessage> messages) {

    if (messages.isEmpty) return;



    final newestMessageAt = messages.last.createdAt.toUtc();

    if (_lastMarkedReadAt != null &&

        !newestMessageAt.isAfter(_lastMarkedReadAt!)) {

      return;

    }

    _lastMarkedReadAt = newestMessageAt;



    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!mounted) return;

      ref

          .read(chatUnreadCountProvider.notifier)

          .markAsRead(timestamp: newestMessageAt);

    });

  }

  void _markConversationAsRead() {
    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    // Mark all messages in this conversation as read
    final messagesAsync = ref.read(dmStreamProvider(widget.partnerId));
    messagesAsync.maybeWhen(
      data: (messages) {
        if (messages.isEmpty) return;
        
        final newestMessageAt = messages.last.createdAt.toUtc();
        
        // Update the global chat last seen
        ref.read(chatUnreadCountProvider.notifier).markAsRead(timestamp: newestMessageAt);

        // Optimistically clear the unread badge locally for instant feedback
        markDmAsReadLocally(widget.partnerId, newestMessageAt);
        ref.invalidate(dmUnreadCountProvider(widget.partnerId));

        final unreadIds = <String>[];
        final normalizedUserId = currentUser.id.trim().toLowerCase();

        for (final message in messages) {
          if (message.senderId != currentUser.id) {
            final readBy = ReadReceiptsTracker.getReadBy(message.id);
            if (!readBy.contains(normalizedUserId)) {
              unreadIds.add(message.id);
            }
          }
        }

        if (unreadIds.isNotEmpty) {
          ReadReceiptsTracker.markMultipleAsRead(unreadIds, currentUser.id);
        }
      },
      orElse: () {},
    );
  }



  String? _findFirstUnreadMessageId(
    List<ChatMessage> messages,
    String currentUserId,
  ) {
    final normalizedUserId = currentUserId.trim().toLowerCase();

    for (final message in messages) {
      if (message.senderId.trim().toLowerCase() == normalizedUserId) {
        continue;
      }

      // Explicit per-message read receipt check
      final readBy = ReadReceiptsTracker.getReadBy(message.id);
      if (!readBy.contains(normalizedUserId)) {
        return message.id;
      }
    }
    return null;
  }



  // ignore: unused_element
  void _handleBack(BuildContext context, Agent? currentUser) {

    if (context.canPop()) {

      context.pop();

      return;

    }



    if (currentUser?.isAdmin == true) {

      context.go('/admin');

    } else if (currentUser?.isAccountant == true) {

      context.go('/accountant');

    } else if (currentUser?.isSupport == true) {

      context.go('/tickets');

    } else if (currentUser?.isSales == true) {

      context.go('/sales');

    } else {

      context.go('/');

    }

  }



  Widget _buildMentionsList() {

    final agentsAsync = ref.watch(agentsListProvider);



    return agentsAsync.when(

      data: (agents) {

        final filteredAgents = agents.where((a) {

          final name = (a['full_name'] ?? a['username'] ?? '')

              .toString()

              .toLowerCase();

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

              final name = (agent['full_name'] ?? agent['username'] ?? '')

                  .toString();

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

    final text = _textCtrl.text;

    final newText = text.replaceRange(

      _mentionStartIndex,

      _textCtrl.selection.baseOffset,

      '@$name ',

    );



    _textCtrl.value = TextEditingValue(

      text: newText,

      selection: TextSelection.collapsed(

        offset: _mentionStartIndex + name.length + 2,

      ),

    );



    setState(() {
      _showMentions = false;
    });
  }

  void _triggerMention() {
    final text = _textCtrl.text;
    final selection = _textCtrl.selection;
    
    int insertOffset = selection.baseOffset;
    if (insertOffset == -1) {
      insertOffset = text.length;
    }
    
    String prefix = '@';
    if (insertOffset > 0 && text[insertOffset - 1] != ' ') {
      prefix = ' @';
    }
    
    final newText = text.replaceRange(insertOffset, insertOffset, prefix);
    
    _textCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertOffset + prefix.length),
    );
    
    setState(() {
      _showMentions = true;
      _mentionQuery = '';
      _mentionStartIndex = insertOffset + (prefix.length - 1);
    });
    
    _messageFocusNode.requestFocus();
  }

  Widget _buildInputArea() {

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12,
        ),

      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showFormattingBar)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildFormattingBar(),
            ),
          // Reply preview
          if (_replyingToMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingToMessage!.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyingToMessage!.content,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // File preview
          if (_selectedFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isUploadingFile
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64748B)),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _selectedFile!.name,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  if (!_isUploadingFile)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: _clearFile,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                return KeyEventResult.ignored;
                              } else {
                                _sendMessage();
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _textCtrl,
                            focusNode: _messageFocusNode,
                            minLines: 1,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: const TextStyle(fontSize: 14, color: AppColors.slate500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              isDense: true,
                              prefixIconConstraints: const BoxConstraints(),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12.0, right: 4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: _showEmojiPicker,
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.emoji_emotions_outlined, color: AppColors.slate500, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showFormattingBar = !_showFormattingBar;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(_showFormattingBar ? Icons.text_format : Icons.text_format, color: _showFormattingBar ? AppColors.primary : AppColors.slate500, size: 20),
                                      ),
                                    ),
                                  ],
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
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.alternate_email, color: AppColors.slate500, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: _showGifPicker,
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.movie_outlined, color: AppColors.slate500, size: 20),
                                      ),
                                    ),
                                  ],
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
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _isUploadingFile
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(9.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                        onPressed: _sendMessage,
                      ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}



  void _confirmDelete(BuildContext context, String messageId) {

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Delete Message'),

        content: const Text('Are you sure you want to delete this message?'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: const Text('Cancel'),

          ),

          TextButton(

            onPressed: () {

              ref

                  .read(chatControllerProvider.notifier)

                  .deleteMessage(messageId);

              Navigator.pop(context);

            },

            child: const Text('Delete', style: TextStyle(color: Colors.red)),

          ),

        ],

      ),

    );

  }

  void _handleReply(ChatMessage message) {
    setState(() {
      _replyingToMessage = message;
    });
    _messageFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  // ignore: unused_element
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.single;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<String?> _uploadFile(PlatformFile file) async {
    try {
      print('Starting file upload: ${file.name}');
      final storage = Supabase.instance.client.storage;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = fileName;
      
      print('Reading file bytes...');
      Uint8List fileBytes;
      
      if (file.bytes != null) {
        // Web platform - bytes are already available
        fileBytes = Uint8List.fromList(file.bytes!);
        print('Using file bytes from picker: ${fileBytes.length}');
      } else if (file.path != null) {
        // Mobile/desktop platform - read from file path
        fileBytes = await File(file.path!).readAsBytes();
        print('File bytes read from path: ${fileBytes.length}');
      } else {
        print('Error: No file bytes or path available');
        return null;
      }
      
      print('Uploading to storage: $filePath');
      await storage.from('chat_attachments').uploadBinary(
        filePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: _getMimeType(file.extension),
          upsert: false,
        ),
      );
      
      print('Upload successful, getting public URL...');
      final publicUrl = storage.from('chat_attachments').getPublicUrl(filePath);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('File upload error: $e');
      return null;
    }
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

  void _handleStarMessage(BuildContext context, String messageId) {
    final agent = ref.read(authProvider);
    if (agent == null) return;

    final repository = ref.read(chatRepositoryProvider);
    repository.toggleStarred(messageId, agent.id);
  }

  void _addReaction(BuildContext context, String reaction, String messageId) {
    final agent = ref.read(authProvider);
    if (agent == null) return;

    final repository = ref.read(chatRepositoryProvider);
    repository.toggleReaction(
      messageId: messageId,
      userId: agent.id,
      emoji: reaction,
    );
  }

  void _showMoreReactions(BuildContext context, String messageId) {
    final moreReactions = [
      '❤️', '🔥', '🎉', '👏', '🙌', '😂', '😮', '😢',
      '🤔', '👀', '💯', '✨', '🚀', '💪', '🤝', '👋',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reaction'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: moreReactions.length,
            itemBuilder: (context, index) {
              final emoji = moreReactions[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _addReaction(context, emoji, messageId);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    const categories = {
      'Smileys': ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😌','😍','🥰','😘','😗','😙','😚','😋','😛','😝','😜','🤪','🤨','🧐','🤓','😎','🤩','🥳','😏','😒','😞','😔','😟','😕','🙁','☹️','😣','😖','😫','😩','🥺','😢','😭','😤','😠','😡','🤬','🤯','😳','🥵','🥶','😱','😨','😰','😥','😓','🤗','🤔','🤭','🤫','🤥','😶','😐','😑','😬','🙄','😯','😦','😧','😮','😲','🥱','😴','🤤','😪','😵','🤐','🥴','🤢','🤮','🤧','😷','🤒','🤕'],
      'Gestures': ['👋','🤚','🖐️','✋','🖖','👌','🤌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','🖕','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','✍️','💅','🤳','💪','🦾','🦿','🦵','🦶','👂','🦻','👃','🧠','🫀','🫁','🦷','🦴','👀','👁️','👅','👄'],
      'People': ['👶','🧒','👦','👧','🧑','👱','👨','🧔','👩','🧓','👴','👵','🙍','🙎','🙅','🙆','💁','🙋','🧏','🙇','🤦','🤷','👮','🕵️','💂','🥷','👷','🤴','👸','👳','👲','🧕','🤵','👰','🤰','🤱','👼','🎅','🤶','🦸','🦹','🧙','🧝','🧛','🧟','🧞','🧜','🧚','👯','🤺','🏇','⛷️','🏂','🪂','🏋️','🤸','🤾','🏌️','🏄','🚣','🧘'],
      'Animals': ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵','🙈','🙉','🙊','🐔','🐧','🐦','🐤','🦆','🦅','🦉','🦇','🐺','🐗','🐴','🦄','🐝','🐛','🦋','🐌','🐞','🐜','🦟','🦗','🕷️','🦂','🐢','🐍','🦎','🦖','🦕','🐙','🦑','🦐','🦞','🦀','🐡','🐟','🐠','🐬','🐳','🐋','🦈','🐊','🐅','🐆','🦓','🦍','🦧','🐘','🦛','🦏','🐪','🐫','🦒','🦘','🦬','🐃','🐂','🐄','🐎','🐖','🐏','🐑','🦙','🐐','🦌','🐕','🐩','🦮','🐕‍🦺','🐈','🐈‍⬛','🪶','🐓','🦃','🦤','🦚','🦜','🦢','🦩','🕊️','🐇','🦝','🦨','🦡','🦫','🦦','🦥','🐁','🐀','🐿️','🦔'],
      'Food': ['🍎','🍊','🍋','🍇','🍓','🫐','🍈','🍒','🍑','🥭','🍍','🥥','🥝','🍅','🫒','🥑','🍆','🥦','🥬','🥒','🌶️','🫑','🧄','🧅','🥔','🍠','🫘','🌽','🍞','🥐','🥖','🫓','🥨','🥯','🧀','🥚','🍳','🥞','🧇','🥓','🥩','🍗','🍖','🌭','🍔','🍟','🍕','🫔','🌮','🌯','🥙','🧆','🥚','🍜','🍝','🍛','🍣','🍱','🥟','🦪','🍤','🍙','🍚','🍘','🍥','🥮','🍢','🧁','🍰','🎂','🍮','🍭','🍬','🍫','🍿','🍩','🍪','🌰','🥜','🍯','🧃','🥤','🧋','☕','🍵','🧉','🍺','🍻','🥂','🍷'],
      'Objects': ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','☮️','✝️','☪️','🕉️','☸️','✡️','🔯','🕎','☯️','☦️','🛐','⛎','🔱','📛','🔰','♻️','✅','❎','🆗','🆙','🆒','🆕','🆓','🔟','🔠','🔡','🔢','🔣','🔤','🅰️','🅱️','🆎','🅾️','🆑','🆘','⛔','📵','🚫','🔕','🔇','🔞','📵','🔴','🟠','🟡','🟢','🔵','🟣','⚫','⚪','🟤'],
    };

    showDialog(
      context: context,
      builder: (ctx) {
        String selectedCategory = categories.keys.first;
        return StatefulBuilder(
          builder: (ctx, setInnerState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              width: 380,
              height: 380,
              child: Column(
                children: [
                  // Category tabs
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      children: categories.keys.map((cat) => GestureDetector(
                        onTap: () => setInnerState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: selectedCategory == cat ? AppColors.primary : AppColors.slate100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              color: selectedCategory == cat ? Colors.white : AppColors.slate600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  const Divider(height: 1),
                  // Emoji grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        childAspectRatio: 1,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: categories[selectedCategory]!.length,
                      itemBuilder: (_, i) {
                        final emoji = categories[selectedCategory]![i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            final pos = _textCtrl.selection.baseOffset;
                            final text = _textCtrl.text;
                            final insert = pos < 0 ? text.length : pos;
                            final newText = text.replaceRange(insert, insert, emoji);
                            _textCtrl.value = TextEditingValue(
                              text: newText,
                              selection: TextSelection.collapsed(offset: insert + emoji.length),
                            );
                            _messageFocusNode.requestFocus();
                          },
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showGifPicker() {
    final sampleGifs = [
      'https://media.giphy.com/media/l0MYGb1LuZ3n7dRnO/giphy.gif',
      'https://media.giphy.com/media/3o7TKr3VTzbhWvzIxe/giphy.gif',
      'https://media.giphy.com/media/l0HlBO7eyXzSZkJri/giphy.gif',
      'https://media.giphy.com/media/xT0xeJpnrWC4XWblEk/giphy.gif',
      'https://media.giphy.com/media/26BRBKqUiq58P6n0y/giphy.gif',
      'https://media.giphy.com/media/l4FGuhL4U2WyjdkaY/giphy.gif',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select GIF'),
        content: SizedBox(
          width: 350,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: sampleGifs.length,
            itemBuilder: (context, index) {
              final gifUrl = sampleGifs[index];
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  _sendGif(gifUrl);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      gifUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendGif(String gifUrl) {
    final agent = ref.read(authProvider);
    if (agent == null) return;

    ref.read(chatControllerProvider.notifier).sendMessage(
      senderId: agent.id,
      senderName: agent.fullName,
      senderRole: agent.role,
      content: '', // Empty content, as the image will show
      receiverId: widget.partnerId,
      senderAvatarUrl: agent.avatarUrl,
      fileUrl: gifUrl,
      fileName: 'giphy.gif',
      fileType: 'gif',
    );
  }
}



// ── Per-user deterministic color ─────────────────────────────────────────────



const _kUserColors = [

  Color(0xFF2563EB), // blue

  Color(0xFF7C3AED), // violet

  Color(0xFFDB2777), // pink

  Color(0xFF059669), // emerald

  Color(0xFFD97706), // amber

  Color(0xFFDC2626), // red

  Color(0xFF0891B2), // cyan

  Color(0xFF65A30D), // lime

  Color(0xFF9333EA), // purple

  Color(0xFFEA580C), // orange

];



Color _userColor(String name) {

  if (name.isEmpty) return _kUserColors[0];

  int hash = 0;

  for (final c in name.codeUnits) {

    hash = (hash * 31 + c) & 0x7fffffff;

  }

  return _kUserColors[hash % _kUserColors.length];

}



// ── Date header ───────────────────────────────────────────────────────────────



class _DateHeader extends StatelessWidget {

  final DateTime date;

  const _DateHeader({required this.date});



  @override

  Widget build(BuildContext context) {

    String text;

    final now = DateTime.now();

    if (date.year == now.year &&

        date.month == now.month &&

        date.day == now.day) {

      text = 'Today';

    } else if (date.year == now.year &&

        date.month == now.month &&

        date.day == now.day - 1) {

      text = 'Yesterday';

    } else {

      text = DateFormat('MMMM d, y').format(date);

    }



    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 20),

      child: Row(

        children: [

          const Expanded(child: Divider(color: AppColors.slate200)),

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Text(

              text,

              style: TextStyle(

                fontSize: 11,

                fontWeight: FontWeight.w600,

                color: AppColors.slate500,

              ),

            ),

          ),

          const Expanded(child: Divider(color: AppColors.slate200)),

        ],

      ),

    );

  }

}



// ── Unread label ───────────────────────────────────────────────────────────────



class _UnreadLabel extends StatelessWidget {

  const _UnreadLabel({super.key});



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 8),

      child: Row(

        children: [

          const Expanded(child: Divider(color: AppColors.slate200)),

          Padding(

            padding: const EdgeInsets.symmetric(horizontal: 16),

            child: Container(

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

              decoration: BoxDecoration(

                color: AppColors.error.withValues(alpha: 0.1),

                borderRadius: BorderRadius.circular(12),

                border: Border.all(

                  color: AppColors.error.withValues(alpha: 0.3),

                ),

              ),

              child: Text(

                'Unread messages',

                style: TextStyle(

                  fontSize: 11,

                  fontWeight: FontWeight.w600,

                  color: AppColors.error,

                ),

              ),

            ),

          ),

          const Expanded(child: Divider(color: AppColors.slate200)),

        ],

      ),

    );

  }

}



class _ChatBubble extends ConsumerWidget {

  final ChatMessage message;

  final bool isMe;

  final VoidCallback onDelete;
  final VoidCallback onReply;



  const _ChatBubble({

    super.key,

    required this.message,

    required this.isMe,

    required this.onDelete,
    required this.onReply,

  });



  Color _userColor(String name) {

    final colors = [

      AppColors.primary,

      AppColors.success,

      AppColors.warning,

      AppColors.error,

      AppColors.info,

    ];

    final index = name.hashCode.abs() % colors.length;

    return colors[index];

  }

  // ignore: unused_element
  bool _isSenderOnline(String senderId, List<Map<String, dynamic>> agents) {
    final now = DateTime.now();
    final senderAgent = agents.firstWhere(
      (a) => (a['id']?.toString() ?? '') == senderId,
      orElse: () => <String, dynamic>{},
    );
    final lastSeen = senderAgent['last_seen'] != null 
        ? DateTime.tryParse(senderAgent['last_seen'].toString()) 
        : null;
    return lastSeen != null && now.difference(lastSeen).inMinutes < 5;
  }

  


  String? _extractTicketId(String content) {

    print('=== TICKET ID EXTRACTION DEBUG ===');

    print('Full content: ${content.length > 200 ? content.substring(0, 200) + '...' : content}');

    

    // Method 1: Standard line-by-line extraction

    for (final line in content.split('\n')) {

      print('Checking line: "$line"');

      if (line.startsWith('TicketID: ')) {

        final ticketId = line.substring('TicketID: '.length).trim();

        print('✅ Found ticket ID (method 1): $ticketId');

        return ticketId;

      }

    }

    

    // Method 2: Regex extraction

    if (content.contains('TicketID:')) {

      final match = RegExp(r'TicketID:\s*([^\s\n]+)').firstMatch(content);

      if (match != null) {

        final ticketId = match.group(1);

        print('✅ Found ticket ID (method 2): $ticketId');

        return ticketId;

      }

    }

    

    // Method 3: Try to extract any UUID-like pattern

    final uuidMatch = RegExp(r'([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})', caseSensitive: false).firstMatch(content);

    if (uuidMatch != null) {

      final ticketId = uuidMatch.group(1);

      print('✅ Found UUID-like ticket ID (method 3): $ticketId');

      return ticketId;

    }

    

    // Method 4: Try to extract any alphanumeric ID that looks like a ticket ID

    final idMatch = RegExp(r'([a-f0-9]{20,})', caseSensitive: false).firstMatch(content);

    if (idMatch != null) {

      final ticketId = idMatch.group(1);

      print('✅ Found long alphanumeric ID (method 4): $ticketId');

      return ticketId;

    }

    

    // Method 5: Fallback - try to find ticket by matching content with existing tickets

    print('Trying fallback method - matching content with existing tickets...');

    // This will be handled in the calling function where we have access to the tickets list

    

    print('❌ No ticket ID found in content');

    print('=== END EXTRACTION DEBUG ===');

    return null;

  }



  String _extractIssueFromContent(String content) {

    for (final line in content.split('\n')) {

      if (line.startsWith('Issue: ')) {

        return line.substring('Issue: '.length).trim();

      }

    }

    return '';

  }



  String _extractCompanyFromContent(String content) {

    for (final line in content.split('\n')) {

      if (line.startsWith('Company: ')) {

        return line.substring('Company: '.length).trim();

      }

    }

    return '';

  }

  bool _isResolvedStatus(String? status) {
    return status == 'Resolved' || status == 'Closed' || status == 'BillRaised' || status == 'BillProcessed';
  }

  Color _statusBorderColor(String? status, {bool isClaimed = false}) {

    // If ticket is resolved/completed, show green border regardless of claim status

    if (_isResolvedStatus(status)) {

      return AppColors.success; // Green for resolved/completed tickets

    }



    // If ticket is claimed, show yellow border

    if (isClaimed) {

      return AppColors.warning; // Yellow for claimed tickets

    }

    

    // For unclaimed tickets, show red border

    switch (status) {

      case 'New':

      case 'Open':

      case 'InProgress':

      case 'OnHold':

      case 'WaitingForCustomer':

      case 'Reopened':

      case null:

        return AppColors.error; // Red for tickets with no status (unclaimed)

      default:

        return AppColors.error; // Red for unknown status (unclaimed)

    }

  }



  Color _getStatusColor(String? status) {

    switch (status) {

      case 'New':

      case 'Open':

        return AppColors.error;

      case 'InProgress':

      case 'OnHold':

      case 'WaitingForCustomer':

        return AppColors.warning;

      case 'Resolved':

      case 'Closed':

      case 'Reopened':

      case 'BillRaised':

      case 'BillProcessed':

        return AppColors.success;

      default:

        return Colors.grey;

    }

  }



  // ignore: unused_element
  String _visibleTicketContent(String content) {

    return content

        .split('\n')

        .where((line) => !line.startsWith('TicketID: '))

        .join('\n');

  }

  String _getAssignedAgentName(String? assignedTo, List<Map<String, dynamic>> agents) {
    if (assignedTo == null || assignedTo.isEmpty) {
      return 'Claimed';
    }
    final agent = agents.where((a) => a['id'] == assignedTo).firstOrNull;
    if (agent != null) {
      return agent['full_name'] ?? agent['username'] ?? 'Claimed';
    }
    return 'Claimed';
  }

  String _getFormattedStatus(String? status) {
    if (status == null) return 'In Progress';

    switch (status) {
      case 'Resolved':
      case 'Closed':
      case 'BillRaised':
      case 'BillProcessed':
        return 'Resolved';
      case 'New':
      case 'Open':
      case 'InProgress':
      case 'OnHold':
      case 'WaitingForCustomer':
      case 'Reopened':
      default:
        return 'In Progress';
    }
  }



  

  Future<void> _claimTicketFromChat(BuildContext context, WidgetRef ref, String? ticketId) async {

    if (ticketId == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Ticket ID not found'),

          backgroundColor: AppColors.error,

        ),

      );

      return;

    }

    

    final currentUser = ref.read(authProvider);

    if (currentUser == null) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('User not authenticated'),

          backgroundColor: AppColors.error,

        ),

      );

      return;

    }



    print('Attempting to claim ticket: $ticketId by user: ${currentUser.id}');



    try {

      print('=== TICKET CLAIM DEBUG ===');

      print('Ticket ID: "$ticketId"');

      print('Current User ID: "${currentUser.id}"');

      print('Current User Name: "${currentUser.username}"');

      print('User Role: "${currentUser.role}"');

      print('Is Support: ${currentUser.isSupport}');

      print('Is Support Head: ${currentUser.isSupportHead}');

      print('Is Agent: ${currentUser.isAgent}');

      

      if (ticketId.isEmpty) {

        print('❌ Invalid ticket ID: "$ticketId"');

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Invalid ticket ID - cannot claim'),

            backgroundColor: AppColors.error,

          ),

        );

        return;

      }

      

      print('Calling assignTicket...');

      final success = await ref.read(ticketAssignerProvider.notifier).assignTicket(ticketId, currentUser.id);

      print('assignTicket returned: $success');



      if (!context.mounted) return;



      if (success) {

        print('✅ Ticket claimed successfully: $ticketId');

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Ticket claimed successfully!'),

            backgroundColor: AppColors.success,

          ),

        );

        // Force refresh the tickets stream to update the UI

        ref.invalidate(rawTicketsStreamProvider);



        // Navigate directly to the ticket resolving page

        context.push('/ticket/$ticketId');

      } else {

        print('❌ Failed to claim ticket: $ticketId - assignTicket returned false');

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Failed to claim ticket - please try again'),

            backgroundColor: AppColors.error,

          ),

        );

      }

      print('=== END CLAIM DEBUG ===');

    } catch (e) {

      print('❌ Exception while claiming ticket: $e');

      print('Stack trace: ${StackTrace.current}');

      if (!context.mounted) return;

      

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Error claiming ticket: ${e.toString()}'),

          backgroundColor: AppColors.error,

        ),

      );

    }

  }



  

  @override

  Widget build(BuildContext context, WidgetRef ref) {

    if (message.isDeleted) {

      return Container(

        padding: const EdgeInsets.symmetric(vertical: 8),

        alignment: Alignment.center,

        child: Text(

          'Message deleted',

          style: TextStyle(

            fontSize: 11,

            color: AppColors.slate400,

            fontStyle: FontStyle.italic,

          ),

        ),

      );

    }

    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.center,

        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,

        children: [

          // Message content
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: _HoverableMessageRow(
                isMe: isMe,
                onReply: onReply,
                onDelete: onDelete,
                message: message,
                child: Column(

                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,

                children: [
                  // File attachment display
                  if (message.fileUrl != null && message.fileName != null)
                    if (message.fileType == 'gif' || message.fileType == 'jpg' || message.fileType == 'jpeg' || message.fileType == 'png' || message.fileType == 'webp')
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: const BoxConstraints(
                          maxWidth: 250,
                          maxHeight: 250,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.fileUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getFileIcon(message.fileType),
                              size: 20,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.fileName!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Attachment',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.download,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () => _downloadFile(message.fileUrl!, message.fileName!),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  // Header with name and timestamp

                  Wrap(
                    alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [

                      if (!isMe) ...[
                        Text(

                          message.senderName,

                          style: TextStyle(

                            fontSize: 15,

                            fontWeight: FontWeight.w600,

                            color: _userColor(message.senderName),

                          ),

                        ),

                        const SizedBox(width: 8),
                      ],

                      Text(

                        DateFormat('h:mm a').format(message.createdAt.toLocal()),

                        style: const TextStyle(

                          fontSize: 12,

                          color: Color(0xFF6B7280),

                        ),

                      ),

                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Text(

                          'You',

                          style: TextStyle(

                            fontSize: 15,

                            fontWeight: FontWeight.w600,

                            color: _userColor(message.senderName),

                          ),

                        ),
                      ],

                      if (message.senderRole.isNotEmpty) ...[

                        const SizedBox(width: 8),



                    Container(

                          padding: const EdgeInsets.symmetric(

                            horizontal: 6,

                            vertical: 2,

                          ),

                          decoration: BoxDecoration(

                            color: _userColor(message.senderName)

                                .withValues(alpha: 0.10),

                            borderRadius: BorderRadius.circular(4),

                          ),

                          child: Text(

                            message.senderRole.toUpperCase(),

                            style: TextStyle(

                              fontSize: 8,

                              fontWeight: FontWeight.w600,

                              color: _userColor(message.senderName),

                            ),

                          ),

                        ),

                      ],

                      const SizedBox(width: 8),

                      // Action menu (shown on hover)
                      const _HoverableActionMenu(),
                    ],

                  ),

                  const SizedBox(height: 4),

                  // Message content with ticket handling

                  _buildSlackStyleMessageContent(context, ref),

                  const SizedBox(height: 6),

                  // Reactions display
                  if (message.reactions.isNotEmpty)
                    _buildReactionsDisplay(context, ref),

                ],

              ),
            ),
          ),
        ),
        ],
      ),

    );

  }



  Widget _buildSlackStyleMessageContent(BuildContext context, WidgetRef ref) {

    final isTicketMessage = message.content.startsWith('Company: ') &&

        message.content.contains('\nIssue: ');



    if (isTicketMessage) {

      final ticketId = _extractTicketId(message.content);

      final currentUser = ref.read(authProvider);

      

      // Debug info

      print('Ticket message detected: ${message.content.length > 50 ? message.content.substring(0, 50) : message.content}...');

      print('Extracted ticket ID: $ticketId');



      return Consumer(

        builder: (context, ref, child) {

          final ticketsAsync = ref.watch(ticketsStreamProvider);

          final agentsAsync = ref.watch(agentsListProvider);



          return ticketsAsync.when(

            data: (tickets) {

              Ticket? ticket;

              

              // Method 1: Try to find by extracted ticket ID

              if (ticketId != null) {

                for (final item in tickets) {

                  if (item.ticketId == ticketId) {

                    ticket = item;

                    print('✅ Found ticket by ID: $ticketId');

                    break;

                  }

                }

              }

              

              // Method 2: Enhanced fallback with timestamp-based matching to prevent cross-assignment

              if (ticket == null && ticketId == null) {

                print('🔍 Trying fallback content matching...');

                final messageIssue = _extractIssueFromContent(message.content);

                final messageCompany = _extractCompanyFromContent(message.content);

                print('Looking for issue: "$messageIssue"');

                print('Looking for company: "$messageCompany"');

                print('Message timestamp: ${message.createdAt}');

                

                // Print all available tickets for debugging

                print('=== ALL AVAILABLE TICKETS ===');

                for (final item in tickets.take(5)) { // Show first 5 tickets

                  print('Ticket: ${item.ticketId} | Issue: "${item.description?.trim() ?? item.title.trim()}" | Status: ${item.status} | Assigned: ${item.assignedTo} | Created: ${item.createdAt}');

                }

                print('=== END TICKETS ===');

                

                // Create a list of potential matches with scores

                List<Map<String, dynamic>> potentialMatches = [];

                

                for (final item in tickets) {

                  final ticketIssue = item.description?.trim() ?? item.title.trim();

                  double score = 0;

                  

                  // Exact issue match gets highest score

                  if (ticketIssue.toLowerCase() == messageIssue.toLowerCase()) {

                    score += 100;

                    print('🎯 Exact issue match for ticket ${item.ticketId}');

                  }

                  // Partial match gets medium score

                  else if (ticketIssue.toLowerCase().contains(messageIssue.toLowerCase()) ||

                           messageIssue.toLowerCase().contains(ticketIssue.toLowerCase())) {

                    score += 50;

                    print('🔍 Partial issue match for ticket ${item.ticketId}');

                  }

                  

                  // Company match adds bonus

                  if (messageCompany.isNotEmpty) {

                    // This would need company info from ticket - skipping for now

                  }

                  

                  // Time proximity - tickets created around the same time get bonus

                  if (item.createdAt != null) {

                    final timeDiff = item.createdAt!.difference(message.createdAt).inMinutes.abs();

                    if (timeDiff < 5) { // Within 5 minutes

                      score += 20;

                      print('⏰ Time proximity bonus for ticket ${item.ticketId} (${timeDiff}min diff)');

                    }

                  }

                  

                  if (score > 0) {

                    potentialMatches.add({

                      'ticket': item,

                      'score': score,

                      'claimed': item.assignedTo != null && item.assignedTo!.isNotEmpty,

                    });

                    print('📊 Ticket ${item.ticketId} scored ${score} points');

                  }

                }

                

                // Sort by score (highest first) and prefer unclaimed tickets

                potentialMatches.sort((a, b) {

                  // First prioritize claimed status (unclaimed first)

                  if (a['claimed'] != b['claimed']) {

                    return a['claimed'] ? 1 : -1;

                  }

                  // Then by score

                  return b['score'].compareTo(a['score']);

                });

                

                // Select the best match

                if (potentialMatches.isNotEmpty) {

                  final bestMatch = potentialMatches.first['ticket'] as Ticket;

                  final score = potentialMatches.first['score'] as int;

                  final wasClaimed = potentialMatches.first['claimed'] as bool;

                  

                  ticket = bestMatch;

                  print('✅ Selected ticket ${bestMatch.ticketId} with score $score');

                  print('✅ Ticket status: ${bestMatch.status} | Assigned: ${bestMatch.assignedTo} | Was claimed: $wasClaimed');

                } else {

                  print('❌ No suitable matches found for this message');

                }

              }

              

              // Method 3: Only show warning if this looks like a new ticket with no matches

              if (ticket == null && message.content.contains('Company:') && message.content.contains('Issue:')) {

                print('🚨 INFO: This appears to be a new ticket message not yet matched to any ticket');

                print('🚨 Message timestamp: ${message.createdAt}');

                print('🚨 Message content: ${message.content}');



              }

              

              // Debug info

              print('Looking for ticket ID: $ticketId');

              print('Total tickets available: ${tickets.length}');

              print('Ticket found: ${ticket != null}');

              if (ticket != null) {

                print('Ticket status: ${ticket.status}, assigned to: ${ticket.assignedTo}');

              }



              final isClaimed = ticket?.assignedTo != null && ticket!.assignedTo!.isNotEmpty;


              final canClaim = currentUser != null; // Anyone can claim tickets now



              // Show claim button only if ticket is not claimed by anyone

              // final showClaimButton = !isClaimed; // Now handled directly in the button condition



              return Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // Compact ticket content

                  InkWell(
                    onTap: ticket != null &&
                        // Allow click if ticket is unclaimed OR claimed by current user
                        (ticket.assignedTo == null ||
                         ticket.assignedTo!.isEmpty ||
                         ticket.assignedTo == currentUser?.id)
                        ? () => context.push('/ticket/${ticket?.ticketId}')
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(


                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),

                      decoration: BoxDecoration(

                        color: Colors.white,

                        borderRadius: BorderRadius.circular(6),

                        border: Border.all(



                          color: _statusBorderColor(ticket?.status, isClaimed: isClaimed),

                          width: 1.5,

                        ),

                        boxShadow: [

                          BoxShadow(

                            color: Colors.black.withValues(alpha: 0.03),

                            blurRadius: 2,

                            offset: const Offset(0, 1),

                          ),

                        ],

                      ),

                    child: Row(

                      crossAxisAlignment: CrossAxisAlignment.center,

                      children: [

                        // Ticket icon and content

                        Expanded(

                          child: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              // Compact ticket info

                              Row(

                                children: [

                                  Icon(

                                    LucideIcons.ticket,

                                    size: 12,

                                    color: _statusBorderColor(ticket?.status, isClaimed: isClaimed),

                                  ),

                                  const SizedBox(width: 4),

                                  Expanded(

                                    child: Text(

                                      _extractIssueFromContent(message.content),

                                      style: const TextStyle(

                                        color: Color(0xFF1F2937),

                                        fontSize: 13,

                                        fontWeight: FontWeight.bold,

                                      ),

                                      maxLines: 1,

                                      overflow: TextOverflow.ellipsis,

                                    ),

                                  ),

                                ],

                              ),

                              // Claimed by text in the center
                              if (isClaimed)
                                Center(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Claimed by ',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        TextSpan(
                                          text: _getAssignedAgentName(ticket.assignedTo, agentsAsync.value ?? []),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' - ${_getFormattedStatus(ticket.status)}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 10,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Company and status info

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  Flexible(
                                    child: Text(

                                    _extractCompanyFromContent(message.content),

                                    style: TextStyle(

                                      color: Colors.grey.shade600,

                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,

                                    ),

                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,

                                  ),
                                  ),

                                  if (ticket != null) ...[

                                    const SizedBox(width: 4),

                                    // Hide "New" status for tickets older than 5 hours
                                    if (!(ticket.status == 'New' &&
                                        ticket.createdAt != null &&
                                        DateTime.now().difference(ticket.createdAt!).inHours > 5))
                                      Container(

                                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),

                                        decoration: BoxDecoration(

                                          color: _getStatusColor(ticket.status).withValues(alpha: 0.1),

                                          borderRadius: BorderRadius.circular(8),

                                        ),

                                        child: Text(

                                          ticket.status,

                                          style: TextStyle(

                                            color: _getStatusColor(ticket.status),

                                            fontSize: 9,

                                            fontWeight: FontWeight.w500,

                                          ),

                                        ),

                                      ),

                                  ],

                                ],

                              ),

                            ],

                          ),

                        ),

                        // Claim button logic - check claimed status first
                        if (isClaimed)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _isResolvedStatus(ticket.status)
                                    ? AppColors.success
                                    : Colors.grey[500],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isResolvedStatus(ticket.status) ? 'Resolved' : 'Claimed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else if (canClaim && 
                            message.content.contains('Company:') && 
                            message.content.contains('Issue:') &&
                            ticket?.status != 'Resolved')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  String? finalTicketId = ticket?.ticketId ?? ticketId;
                                  
                                  // Fallback: if no ticket ID but we have a ticket object, use its ID
                                  if (finalTicketId == null && ticket != null) {
                                    finalTicketId = ticket.ticketId;
                                    print('?? Using fallback ticket ID from ticket object: $finalTicketId');
                                  }
                                  
                                  // Final fallback: try to find ticket by content matching
                                  if (finalTicketId == null) {
                                    print('?? No ticket ID found, trying content-based claim...');
                                    final messageIssue = _extractIssueFromContent(message.content);
                                    print('?? Looking for ticket with issue: "$messageIssue"');
                                    
                                    // Find the best matching ticket for claiming
                                    for (final item in tickets) {
                                      final ticketIssue = item.description?.trim() ?? item.title.trim();
                                      if (ticketIssue.toLowerCase() == messageIssue.toLowerCase()) {
                                        finalTicketId = item.ticketId;
                                        print('? Found matching ticket for claim: ${item.ticketId}');
                                        break;
                                      }
                                    }
                                  }
                                  
                                  if (finalTicketId != null) {
                                    print('?? Attempting to claim with ticket ID: $finalTicketId');
                                    print('?? Ticket object found: ${ticket != null}');
                                    if (ticket != null) {
                                      print('?? Ticket details: ID=${ticket.ticketId}, Status=${ticket.status}, Assigned=${ticket.assignedTo}');
                                    }
                                    _claimTicketFromChat(context, ref, finalTicketId);
                                  } else {
                                    print('? Could not find any ticket ID to claim');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not find ticket to claim - please try again'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFCC00),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Claim',
                                    style: TextStyle(
                                      color: Color(0xFFE65100),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )                      ],

                    ),

                  ),
                ),
                ],

              );

            },

            loading: () => const SizedBox(

              height: 40,

              child: Center(child: CircularProgressIndicator()),

            ),

            error: (error, stack) => Text(

              'Error loading tickets: ${error.toString()}',

              style: TextStyle(color: AppColors.error, fontSize: 12),

            ),

          );

        },

      );

    }



    // Regular message
    if (message.content.isEmpty && message.replyToMessageId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply quote — inside the bubble, WhatsApp style
          if (message.replyToMessageId != null && message.replyToContent != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.primary.withValues(alpha: 0.6),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.replyToSenderName ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.95)
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.replyToContent!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          Builder(
            builder: (context) {
              String displayContent = message.content;
              String? mentionId;
              final mentionRegExp = RegExp(r'\[MentionID:([^\]]+)\]');
              final match = mentionRegExp.firstMatch(displayContent);
              if (match != null) {
                mentionId = match.group(1);
                displayContent = displayContent.replaceAll(match.group(0)!, '').trim();
              }
              
              return Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _RichMessageText(
                    content: displayContent,
                    isMe: isMe,
                    richTextDelta: message.richTextDelta,
                  ),
                  if (mentionId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        label: const Text('Go to Message'),
                        onPressed: () {
                          GoRouter.of(context).go('/chat?highlightMsgId=$mentionId');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );

  }

  Widget _buildReactionsDisplay(BuildContext context, WidgetRef ref) {
    // Group reactions by emoji and count
    final Map<String, int> reactionCounts = {};
    for (final reaction in message.reactions) {
      final emoji = reaction['emoji'] as String? ?? '';
      if (emoji.isNotEmpty) {
        reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
      }
    }

    final currentUser = ref.read(authProvider);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: reactionCounts.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;

        // Check if current user has reacted with this emoji
        final hasReacted = message.reactions.any(
          (r) => r['emoji'] == emoji && r['user_id'] == currentUser?.id,
        );

        return InkWell(
          onTap: () {
            // Toggle reaction
            final state = context.findAncestorStateOfType<_DirectMessagePageState>();
            state?._addReaction(context, emoji, message.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasReacted
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: hasReacted ? AppColors.primary : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

}

// ── Hoverable message wrapper (detects hover over entire message) ───────────────
class _HoverableMessageRow extends StatefulWidget {
  final bool isMe;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final Widget child;
  final ChatMessage message;

  const _HoverableMessageRow({
    required this.isMe,
    required this.onReply,
    required this.onDelete,
    required this.child,
    required this.message,
  });

  @override
  State<_HoverableMessageRow> createState() => _HoverableMessageRowState();
}

class _HoverableMessageRowState extends State<_HoverableMessageRow> {
  bool _isHovering = false;

  void _addReaction(BuildContext context, String reaction, String messageId) {
    // Find the parent _DirectMessagePageState and call its method
    final state = context.findAncestorStateOfType<_DirectMessagePageState>();
    state?._addReaction(context, reaction, messageId);
  }

  void _showMoreReactions(BuildContext context, String messageId) {
    // Find the parent _DirectMessagePageState and call its method
    final state = context.findAncestorStateOfType<_DirectMessagePageState>();
    state?._showMoreReactions(context, messageId);
  }

  void _handleStarMessage(BuildContext context, String messageId) {
    // Find the parent _DirectMessagePageState and call its method
    final state = context.findAncestorStateOfType<_DirectMessagePageState>();
    state?._handleStarMessage(context, messageId);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        final isMobile = MediaQuery.of(context).size.width < 900;
        if (isMobile) {
          setState(() => _isHovering = true);
        }
      },
      onTap: () {
        final isMobile = MediaQuery.of(context).size.width < 900;
        if (isMobile && _isHovering) {
          setState(() => _isHovering = false);
        }
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: _HoverableActionMenuContext(
          isMe: widget.isMe,
          onReply: widget.onReply,
          onDelete: widget.onDelete,
          onAddReaction: (context, reaction, messageId) {
            _addReaction(context, reaction, messageId);
            final isMobile = MediaQuery.of(context).size.width < 900;
            if (isMobile) setState(() => _isHovering = false);
          },
          onShowMoreReactions: (context, messageId) => _showMoreReactions(context, messageId),
          onHandleStarMessage: (context, messageId) => _handleStarMessage(context, messageId),
          isHovering: _isHovering,
          messageId: widget.message.id,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Context provider for hover state ─────────────────────────────────────────────
class _HoverableActionMenuContext extends InheritedWidget {
  final bool isHovering;
  final bool isMe;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final Function(BuildContext, String, String) onAddReaction;
  final Function(BuildContext, String) onShowMoreReactions;
  final Function(BuildContext, String) onHandleStarMessage;
  final String messageId;

  const _HoverableActionMenuContext({
    required this.isHovering,
    required this.isMe,
    required this.onReply,
    required this.onDelete,
    required this.onAddReaction,
    required this.onShowMoreReactions,
    required this.onHandleStarMessage,
    required this.messageId,
    required Widget child,
  }) : super(child: child);

  static _HoverableActionMenuContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_HoverableActionMenuContext>()!;
  }

  @override
  bool updateShouldNotify(_HoverableActionMenuContext oldWidget) {
    return isHovering != oldWidget.isHovering;
  }
}

// ── Hoverable action menu widget (simple, no overlay) ─────────────────────────────
class _HoverableActionMenu extends StatelessWidget {
  const _HoverableActionMenu();

  @override
  Widget build(BuildContext context) {
    final hoverContext = _HoverableActionMenuContext.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return AnimatedOpacity(
      opacity: hoverContext.isHovering ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reactions
            _buildReactionButton(
              emoji: '👍',
              tooltip: 'Thumbs up',
              onTap: () => hoverContext.onAddReaction(context, '👍', hoverContext.messageId),
            ),
            _buildReactionButton(
              emoji: '😊',
              tooltip: 'Smile',
              onTap: () => hoverContext.onAddReaction(context, '😊', hoverContext.messageId),
            ),
            _buildReactionButton(
              emoji: '✅',
              tooltip: 'Check',
              onTap: () => hoverContext.onAddReaction(context, '✅', hoverContext.messageId),
            ),
            // More reactions button
            _buildMoreReactionsButton(
              tooltip: 'More reactions',
              onTap: () => hoverContext.onShowMoreReactions(context, hoverContext.messageId),
            ),
            const SizedBox(width: 4),
            // Actions
            _buildIconButton(
              icon: Icons.reply,
              tooltip: 'Reply',
              onTap: hoverContext.onReply,
            ),
            if (hoverContext.isMe)
              _buildIconButton(
                icon: Icons.delete,
                tooltip: 'Delete',
                iconColor: Colors.red,
                onTap: hoverContext.onDelete,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton({
    required String emoji,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreReactionsButton({
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    '😀',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 10,
                      color: Color(0xFF6B7280),
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

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF6B7280),
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

// ── Rich message text — renders **bold**, _italic_, ~~strike~~, <u>underline</u> ──
// Supports combinations: **_bold italic_**, <u>**bold underline**</u>, etc.
// Also handles block-level: ordered lists, bullet lists, blockquotes, code blocks.

class _RichMessageText extends StatelessWidget {
  final String content;
  final bool isMe;
  final List<dynamic>? richTextDelta;

  const _RichMessageText({
    required this.content,
    required this.isMe,
    this.richTextDelta,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback to markdown-style rendering for plain text or if delta parsing fails
    final textColor = isMe ? Colors.white : const Color(0xFF1F2937);
    final mutedColor = isMe ? Colors.white70 : const Color(0xFF6B7280);
    final base = TextStyle(color: textColor, fontSize: 14, height: 1.4);

    // Split into lines and group consecutive list/quote/code-block runs
    final lines = content.split('\n');
    final spans = <InlineSpan>[];

    // Code block state
    bool inCodeBlock = false;
    final codeBuffer = StringBuffer();

    void flushCodeBlock() {
      if (codeBuffer.isNotEmpty) {
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.15)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              codeBuffer.toString().trimRight(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                height: 1.5,
              ),
            ),
          ),
        ));
        codeBuffer.clear();
      }
    }

    // Ordered list: track consecutive numbered items
    int? listCounter; // non-null while building an ordered list
    bool inBulletList = false;
    final listItemSpans = <InlineSpan>[];

    void flushList() {
      if (listItemSpans.isNotEmpty) {
        spans.add(WidgetSpan(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: listItemSpans
                  .map((s) => Text.rich(TextSpan(children: [s])))
                  .toList(),
            ),
          ),
        ));
        listItemSpans.clear();
      }
      listCounter = null;
      inBulletList = false;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // ── Code block toggle ─────────────────────────────────────────────
      if (line.trimRight() == '```') {
        if (inCodeBlock) {
          inCodeBlock = false;
          flushList();
          flushCodeBlock();
        } else {
          flushList();
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        if (codeBuffer.isNotEmpty) codeBuffer.write('\n');
        codeBuffer.write(line);
        continue;
      }

      // ── Ordered list: "1. text", "2. text", … ─────────────────────────
      final orderedMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (orderedMatch != null) {
        final num = int.tryParse(orderedMatch.group(1)!) ?? 1;
        final itemText = orderedMatch.group(2)!;
        if (!inBulletList && listCounter == null) {
          // start new ordered list
          listCounter = num;
        } else if (inBulletList) {
          flushList();
          listCounter = num;
        }
        final numSpan = TextSpan(
          text: '$num.  ',
          style: base.copyWith(fontWeight: FontWeight.bold, color: mutedColor),
        );
        final contentSpan = _InlineParser(text: itemText, base: base).parse();
        listItemSpans.add(TextSpan(children: [
          WidgetSpan(child: const SizedBox(width: 4)),
          numSpan,
          contentSpan,
          const TextSpan(text: '\n'),
        ]));
        continue;
      }

      // ── Bullet list: "- text" or "* text" ─────────────────────────────
      final bulletMatch = RegExp(r'^[-*]\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final itemText = bulletMatch.group(1)!;
        if (listCounter != null) {
          flushList();
        }
        inBulletList = true;
        final bulletSpan = TextSpan(
          text: '•  ',
          style: base.copyWith(fontWeight: FontWeight.bold, color: mutedColor),
        );
        final contentSpan = _InlineParser(text: itemText, base: base).parse();
        listItemSpans.add(TextSpan(children: [
          WidgetSpan(child: const SizedBox(width: 4)),
          bulletSpan,
          contentSpan,
          const TextSpan(text: '\n'),
        ]));
        continue;
      }

      // ── Not a list line — flush any pending list ───────────────────────
      if (listItemSpans.isNotEmpty) flushList();

      // ── Blockquote: "> text" ───────────────────────────────────────────
      final quoteMatch = RegExp(r'^>\s*(.*)$').firstMatch(line);
      if (quoteMatch != null) {
        final quoteText = quoteMatch.group(1)!;
        spans.add(WidgetSpan(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isMe ? Colors.white54 : AppColors.primary.withValues(alpha: 0.5),
                  width: 3,
                ),
              ),
            ),
            child: Text.rich(
              _InlineParser(
                text: quoteText,
                base: base.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isMe ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ).parse(),
            ),
          ),
        ));
        if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
        continue;
      }

      // ── Plain / inline-formatted line ─────────────────────────────────
      spans.add(_InlineParser(text: line, base: base).parse());
      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }

    // Flush any remaining code block or list
    flushList();
    if (inCodeBlock) flushCodeBlock();

    return Text.rich(TextSpan(children: spans));
  }
}

// ── Inline parser — recursive, handles nested/combined formats ────────────────

class _InlineParser {
  final String text;
  final TextStyle base;

  final bool bold;
  final bool italic;
  final bool strikethrough;
  final bool underline;

  _InlineParser({
    required this.text,
    required this.base,
    this.bold = false,
    this.italic = false,
    this.strikethrough = false,
    this.underline = false,
  });

  static final _tokenPattern = RegExp(
    r'\*\*\*'
    r'|\*\*'
    r'|__'
    r'|\*(?!\*)'
    r'|_(?!_)'
    r'|~~'
    r'|<u>'
    r'|<\/u>'
    r'|`[^`]+`',   // inline code
  );

  TextSpan parse() {
    final spans = <InlineSpan>[];
    int pos = 0;

    while (pos < text.length) {
      final match = _tokenPattern.firstMatch(text.substring(pos));
      if (match == null) {
        spans.add(_plain(text.substring(pos)));
        break;
      }

      final tokenStart = pos + match.start;
      final tokenEnd   = pos + match.end;
      final token      = match.group(0)!;

      if (tokenStart > pos) {
        spans.add(_plain(text.substring(pos, tokenStart)));
      }

      // ── Inline code ──
      if (token.startsWith('`') && token.endsWith('`') && token.length > 1) {
        final codeText = token.substring(1, token.length - 1);
        spans.add(WidgetSpan(
          baseline: TextBaseline.alphabetic,
          alignment: PlaceholderAlignment.baseline,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: base.color?.withValues(alpha: 0.12) ?? Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              codeText,
              style: base.copyWith(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ));
        pos = tokenEnd;
        continue;
      }

      String? closeToken;
      bool newBold      = bold;
      bool newItalic    = italic;
      bool newStrike    = strikethrough;
      bool newUnderline = underline;

      if (token == '***') {
        closeToken = '***'; newBold = true; newItalic = true;
      } else if (token == '**' || token == '__') {
        closeToken = token; newBold = true;
      } else if (token == '*' || token == '_') {
        closeToken = token; newItalic = true;
      } else if (token == '~~') {
        closeToken = '~~'; newStrike = true;
      } else if (token == '<u>') {
        closeToken = '</u>'; newUnderline = true;
      } else if (token == '</u>') {
        pos = tokenEnd;
        continue;
      }

      final closeIdx = text.indexOf(closeToken!, tokenEnd);
      if (closeIdx == -1) {
        spans.add(_plain(token));
        pos = tokenEnd;
        continue;
      }

      final inner = text.substring(tokenEnd, closeIdx);
      final innerSpan = _InlineParser(
        text:          inner,
        base:          base,
        bold:          newBold,
        italic:        newItalic,
        strikethrough: newStrike,
        underline:     newUnderline,
      ).parse();

      spans.add(innerSpan);
      pos = closeIdx + closeToken.length;
    }

    TextDecoration? deco;
    if (strikethrough && underline) {
      deco = TextDecoration.combine([TextDecoration.lineThrough, TextDecoration.underline]);
    } else if (strikethrough) {
      deco = TextDecoration.lineThrough;
    } else if (underline) {
      deco = TextDecoration.underline;
    }

    final style = base.copyWith(
      fontWeight:      bold   ? FontWeight.bold   : null,
      fontStyle:       italic ? FontStyle.italic  : null,
      decoration:      deco,
      decorationColor: deco != null ? base.color : null,
    );

    return TextSpan(style: style, children: spans);
  }

  InlineSpan _plain(String t) => TextSpan(text: t, style: _currentStyle());

  TextStyle _currentStyle() {
    TextDecoration? deco;
    if (strikethrough && underline) {
      deco = TextDecoration.combine([TextDecoration.lineThrough, TextDecoration.underline]);
    } else if (strikethrough) {
      deco = TextDecoration.lineThrough;
    } else if (underline) {
      deco = TextDecoration.underline;
    }
    return base.copyWith(
      fontWeight:      bold   ? FontWeight.bold   : null,
      fontStyle:       italic ? FontStyle.italic  : null,
      decoration:      deco,
      decorationColor: deco != null ? base.color : null,
    );
  }
}


// ── Outlined text — white fill with black stroke ──────────────────────────────

// ignore: unused_element
class _OutlinedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  const _OutlinedText({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Stroke layer (black outline)
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: 1.5,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        // Fill layer (white inside)
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: 1.5,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CallButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Icon(icon, size: 18, color: Colors.green.shade700),
        ),
      ),
    );
  }
}
