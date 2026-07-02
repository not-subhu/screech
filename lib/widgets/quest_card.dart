import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

/// The app's signature interaction: a frosted-glass, trading-card-style
/// quest entry with a gradient rarity stripe down the left edge. Tapping
/// the check ring triggers a coin-burst pop.
class QuestCard extends ConsumerStatefulWidget {
  const QuestCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  @override
  ConsumerState<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends ConsumerState<QuestCard> {
  bool _justCompleted = false;

  Color get _priorityColor {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
    }
  }

  String get _priorityLabel {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.medium:
        return 'MEDIUM';
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.urgent:
        return 'URGENT';
    }
  }

  bool get _isOverdue {
    final due = widget.task.dueAt;
    if (due == null || widget.task.isCompleted) return false;
    return due.isBefore(DateTime.now());
  }

  bool get _isDueSoon {
    final due = widget.task.dueAt;
    if (due == null || widget.task.isCompleted) return false;
    final diff = due.difference(DateTime.now());
    return diff.inMinutes > 0 && diff.inMinutes <= 60;
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);

    Widget card = LiquidGlass(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      borderRadius: 18,
      borderColor: _isOverdue ? AppColors.urgentRed.withOpacity(0.6) : null,
      child: _GlowIfDueSoon(
        active: _isDueSoon,
        color: palette.accent,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Signature rarity stripe
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: task.isCompleted
                      ? LinearGradient(
                          colors: [
                            AppColors.mint.withOpacity(0.5),
                            AppColors.mint.withOpacity(0.2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [palette.accent, AppColors.mint, AppColors.coinGold],
                        ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _priorityColor.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _priorityLabel,
                                      style: TextStyle(
                                        color: _priorityColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  if (task.createdByAi) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.auto_awesome,
                                        size: 12, color: AppColors.mint),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                task.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? palette.textMuted
                                          : palette.textPrimary,
                                    ),
                              ),
                              if (task.dueAt != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 13,
                                      color: _isOverdue
                                          ? AppColors.urgentRed
                                          : palette.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(task.dueAt!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isOverdue
                                            ? AppColors.urgentRed
                                            : palette.textMuted,
                                        fontWeight: _isOverdue
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CompletionRing(
                          coinValue: task.coinValue,
                          isCompleted: task.isCompleted,
                          accent: palette.accent,
                          onTap: () {
                            if (!task.isCompleted) {
                              setState(() => _justCompleted = true);
                              widget.onComplete();
                            }
                          },
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
    );

    if (_justCompleted) {
      card = card
          .animate()
          .shake(duration: 280.ms, hz: 4, offset: const Offset(2, 0))
          .then()
          .scale(
            duration: 200.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.03, 1.03),
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            duration: 200.ms,
            begin: const Offset(1.03, 1.03),
            end: const Offset(1, 1),
          );
    }

    return card;
  }
}

/// Wraps content with a soft accent-colored glow when the task is due soon
/// — kept as a thin decorative layer so it composes cleanly with the glass
/// card underneath instead of fighting its BoxDecoration.
class _GlowIfDueSoon extends StatelessWidget {
  const _GlowIfDueSoon({required this.child, required this.active, required this.color});

  final Widget child;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, spreadRadius: 1)],
      ),
      child: child,
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({
    required this.coinValue,
    required this.isCompleted,
    required this.accent,
    required this.onTap,
  });

  final int coinValue;
  final bool isCompleted;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCompleted
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [accent, accent.withOpacity(0.75)],
                    ),
              color: isCompleted ? AppColors.surfaceBorder : null,
              boxShadow: isCompleted
                  ? null
                  : [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.radio_button_unchecked,
              color: isCompleted ? AppColors.mint : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: AppColors.coinGold, size: 12),
              const SizedBox(width: 2),
              Text(
                '$coinValue',
                style: const TextStyle(
                  color: AppColors.coinGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
