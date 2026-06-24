import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatToastOverlay extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const ChatToastOverlay({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newMessage = ref.watch(chatNewMessageEventProvider);
    final aroundTallyNewMessage = ref.watch(allAroundTallyNewMessageEventProvider);
    final onChatPage = currentPath.startsWith('/chat');
    final onAroundTallyPage = currentPath.startsWith('/channel/all-aroundtally');

    return Stack(
      children: [
        child,
        if (newMessage != null && !onChatPage)
          Positioned(
            bottom: 28,
            // Use left + right so the card never overflows the screen
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: _ChatToast(
                key: ValueKey(newMessage.id),
                message: newMessage,
                channel: 'support-chat',
                onTap: () {
                  ref.read(chatNewMessageEventProvider.notifier).clear();
                  context.go('/chat');
                },
                onDismiss: () =>
                    ref.read(chatNewMessageEventProvider.notifier).clear(),
              ),
            ),
          ),
        if (aroundTallyNewMessage != null && !onAroundTallyPage)
          Positioned(
            bottom: 28,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: _ChatToast(
                key: ValueKey(aroundTallyNewMessage.id),
                message: aroundTallyNewMessage,
                channel: 'all-aroundtally',
                onTap: () {
                  ref.read(allAroundTallyNewMessageEventProvider.notifier).clear();
                  context.go('/channel/all-aroundtally');
                },
                onDismiss: () =>
                    ref.read(allAroundTallyNewMessageEventProvider.notifier).clear(),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Animated toast ────────────────────────────────────────────────────────────

class _ChatToast extends StatefulWidget {
  final ChatMessage message;
  final String channel;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ChatToast({
    super.key,
    required this.message,
    required this.channel,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_ChatToast> createState() => _ChatToastState();
}

class _ChatToastState extends State<_ChatToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _ctrl.forward();
    _autoTimer = Timer(
      const Duration(seconds: 4),
      () => _animateOut(widget.onDismiss),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateOut(VoidCallback callback) async {
    _autoTimer?.cancel();
    if (!mounted) return;
    await _ctrl.animateTo(0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInCubic);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: _ChatToastCard(
          message: widget.message,
          channel: widget.channel,
          onTap: () => _animateOut(widget.onTap),
          onDismiss: () => _animateOut(widget.onDismiss),
        ),
      ),
    );
  }
}

// ── Per-user deterministic color (same palette as chat page) ─────────────────
const _kUserColors = [
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF0891B2),
  Color(0xFF65A30D),
  Color(0xFF9333EA),
  Color(0xFFEA580C),
];

Color _userColor(String name) {
  if (name.isEmpty) return _kUserColors[0];
  int hash = 0;
  for (final c in name.codeUnits) {
    hash = (hash * 31 + c) & 0x7fffffff;
  }
  return _kUserColors[hash % _kUserColors.length];
}

// ── Premium card ──────────────────────────────────────────────────────────────

class _ChatToastCard extends StatelessWidget {
  final ChatMessage message;
  final String channel;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ChatToastCard({
    required this.message,
    required this.channel,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final initial = message.senderName.isNotEmpty
        ? message.senderName[0].toUpperCase()
        : '?';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: SelectionContainer.disabled(
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF1E40AF),
              Color(0xFF1D4ED8),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.55),
              blurRadius: 20,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _userColor(message.senderName),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Name + label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  message.senderName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    letterSpacing: 0.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      channel == 'all-aroundtally'
                                          ? LucideIcons.hash
                                          : LucideIcons.messageSquare,
                                      size: 9,
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      channel == 'all-aroundtally' ? 'All-AroundTally' : 'Support',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message.content,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dismiss
                    GestureDetector(
                      onTap: onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}
