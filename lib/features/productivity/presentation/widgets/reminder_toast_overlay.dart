import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/entities/reminder.dart';
import '../providers/reminder_provider.dart';

class ReminderToastOverlay extends ConsumerWidget {
  final Widget child;

  const ReminderToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeReminders = ref.watch(lastTriggeredReminderProvider);

    return Stack(
      children: [
        child,
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: activeReminders
                .map(
                  (reminder) => _ReminderToast(
                    key: ValueKey(reminder.id),
                    reminder: reminder,
                    onDone: () {
                      ref
                          .read(remindersProvider.notifier)
                          .completeReminder(reminder.id);
                      ref
                          .read(lastTriggeredReminderProvider.notifier)
                          .dismiss(reminder.id);
                    },
                    onDismiss: () {
                      ref
                          .read(lastTriggeredReminderProvider.notifier)
                          .dismiss(reminder.id);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ── Single animated toast ─────────────────────────────────────────────────────

class _ReminderToast extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onDone;
  final VoidCallback onDismiss;

  const _ReminderToast({
    super.key,
    required this.reminder,
    required this.onDone,
    required this.onDismiss,
  });

  @override
  State<_ReminderToast> createState() => _ReminderToastState();
}

class _ReminderToastState extends State<_ReminderToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateOut(VoidCallback callback) async {
    await _ctrl.animateTo(0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInCubic);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: _ReminderCard(
            reminder: widget.reminder,
            onDone: () => _animateOut(widget.onDone),
            onDismiss: () => _animateOut(widget.onDismiss),
          ),
        ),
      ),
    );
  }
}

// ── Premium card ──────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onDone;
  final VoidCallback onDismiss;

  const _ReminderCard({
    required this.reminder,
    required this.onDone,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.bellRing,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REMINDER',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              reminder.companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.1,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
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

                // ── Body ──────────────────────────────────────────────
                if (reminder.phoneNumber.isNotEmpty || reminder.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reminder.phoneNumber.isNotEmpty)
                          Row(
                            children: [
                              Icon(LucideIcons.phone,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.55)),
                              const SizedBox(width: 5),
                              Text(
                                reminder.phoneNumber,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        if (reminder.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(LucideIcons.fileText,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: 0.55)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  reminder.notes,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    decoration: TextDecoration.none,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                // ── Divider ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),

                // ── Mark as Done ──────────────────────────────────────
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDone,
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.checkCircle,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Mark as Done',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
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
}
