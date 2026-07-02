import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';

// ─── Inline token regex ───────────────────────────────────────────────────────
// Matches: p! p1 p2 p3 | today | tomorrow | in N days | "26 july" | "july 26"
// Note: p! uses \b only on the left side (! is non-word so right \b never fires).
final _tokenRx = RegExp(
  r'(\bp[!123](?=\s|$|\W)'
  r'|\btoday\b'
  r'|\btomorrow\b'
  r'|in \d+ days?'
  r'|\b\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*'
  r'|(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}\b'
  r')',
  caseSensitive: false,
);

// ─── Smart controller ─────────────────────────────────────────────────────────
class _SmartTaskController extends TextEditingController {
  Color highlightColor;

  _SmartTaskController({required this.highlightColor});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!value.isComposingRangeValid || !withComposing) {
      return _buildHighlighted(text, style);
    }
    final composingStyle =
        (style ?? const TextStyle()).merge(const TextStyle(decoration: TextDecoration.underline));
    return TextSpan(style: style, children: [
      TextSpan(text: value.composing.textBefore(value.text), style: style),
      TextSpan(text: value.composing.textInside(value.text), style: composingStyle),
      _buildHighlighted(value.composing.textAfter(value.text), style),
    ]);
  }

  TextSpan _buildHighlighted(String text, TextStyle? base) {
    final spans = <TextSpan>[];
    int last = 0;
    for (final m in _tokenRx.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: base));
      }
      spans.add(TextSpan(
        text: m.group(0),
        style: (base ?? const TextStyle()).copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w800,
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: base));
    }
    return TextSpan(style: base, children: spans);
  }
}

// ─── Parsers ──────────────────────────────────────────────────────────────────
DateTime? _parseDate(String text) {
  final t = text.toLowerCase();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (_tokenRx.hasMatch(t) == false) return null;

  if (RegExp(r'\btoday\b').hasMatch(t)) return today;
  if (RegExp(r'\btomorrow\b').hasMatch(t)) return today.add(const Duration(days: 1));

  final inDays = RegExp(r'in (\d+) days?').firstMatch(t);
  if (inDays != null) {
    final d = int.tryParse(inDays.group(1)!);
    if (d != null) return today.add(Duration(days: d));
  }

  const monthNames = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];
  for (int i = 0; i < monthNames.length; i++) {
    final mn = monthNames[i];
    final m1 = RegExp(r'(\d{1,2})\s+' + mn + r'\w*').firstMatch(t);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!);
      if (day != null) {
        var d = DateTime(now.year, i + 1, day);
        if (d.isBefore(today)) d = DateTime(now.year + 1, i + 1, day);
        return d;
      }
    }
    final m2 = RegExp(mn + r'\w*\s+(\d{1,2})').firstMatch(t);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      if (day != null) {
        var d = DateTime(now.year, i + 1, day);
        if (d.isBefore(today)) d = DateTime(now.year + 1, i + 1, day);
        return d;
      }
    }
  }
  return null;
}

TaskPriority? _parsePriority(String text) {
  final t = text.toLowerCase();
  // Use word-boundary on left; lookahead on right for p! (! is non-word char)
  if (RegExp(r'\bp!(?=\s|$|\W)').hasMatch(t)) return TaskPriority.urgent;
  if (RegExp(r'\bp1\b').hasMatch(t)) return TaskPriority.high;
  if (RegExp(r'\bp2\b').hasMatch(t)) return TaskPriority.medium;
  if (RegExp(r'\bp3\b').hasMatch(t)) return TaskPriority.low;
  return null;
}

String _friendlyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(d.year, d.month, d.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return 'today';
  if (diff == 1) return 'tomorrow';
  if (diff > 1 && diff <= 6) return 'in $diff days';
  return DateFormat('d MMM').format(d);
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class QuickAddPanel extends ConsumerStatefulWidget {
  const QuickAddPanel({
    super.key,
    required this.accentColor,
    required this.isDark,
    required this.onClose,
  });

  final Color accentColor;
  final bool isDark;
  final VoidCallback onClose;

  @override
  ConsumerState<QuickAddPanel> createState() => _QuickAddPanelState();
}

class _QuickAddPanelState extends ConsumerState<QuickAddPanel> {
  late _SmartTaskController _titleCtrl;
  final FocusNode _focus = FocusNode();
  DateTime? _manualDate;
  bool _dateSuppressed = false; // true when user explicitly removes a detected date
  TaskPriority? _manualPriority;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = _SmartTaskController(highlightColor: widget.accentColor);
    _titleCtrl.addListener(_onTextChanged);
    // Auto-focus immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(QuickAddPanel old) {
    super.didUpdateWidget(old);
    if (old.accentColor != widget.accentColor) {
      _titleCtrl.highlightColor = widget.accentColor;
    }
  }

  void _onTextChanged() {
    // Reset date suppression if the text no longer contains any date token —
    // this lets a user type a new date after dismissing a previous one.
    if (_dateSuppressed && _parseDate(_titleCtrl.text) == null) {
      _dateSuppressed = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTextChanged);
    _titleCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ── Detected tokens from text ──────────────────────────────────────────────
  DateTime? get _detectedDate => _parseDate(_titleCtrl.text);
  TaskPriority? get _detectedPriority => _parsePriority(_titleCtrl.text);

  // Final resolved values (manual overrides detected; suppressed = no date)
  DateTime? get _resolvedDate {
    if (_dateSuppressed) return null;
    return _manualDate ?? _detectedDate;
  }

  TaskPriority get _resolvedPriority =>
      _manualPriority ?? _detectedPriority ?? TaskPriority.medium;

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    // Strip parsed tokens from title
    var title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    // Remove p!, p1, p2, p3 tokens from title
    // p! needs lookahead-based boundary (! is non-word, \b after it fails)
    title = title
        .replaceAll(
            RegExp(r'\bp[!123](?=\s|$|\W)', caseSensitive: false), '')
        .trim();
    // Remove date tokens
    title = title
        .replaceAll(
            RegExp(
                r'\b(today|tomorrow|in \d+ days?'
                r'|\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*'
                r'|(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}\b)',
                caseSensitive: false),
            '')
        .trim();
    // Clean multiple spaces
    title = title.replaceAll(RegExp(r'  +'), ' ').trim();

    if (title.isEmpty) {
      setState(() => _saving = false);
      return;
    }

    await ref.read(tasksProvider.notifier).addTask(
          title: title,
          dueAt: _resolvedDate,
          priority: _resolvedPriority,
        );

    if (mounted) {
      setState(() {
        _saving = false;
        _manualDate = null;
        _dateSuppressed = false;
        _manualPriority = null;
      });
      _titleCtrl.clear();
      // Re-focus to keep keyboard up
      _focus.requestFocus();
    }
  }

  Future<void> _pickDate() async {
    _focus.unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: widget.accentColor,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _manualDate = picked);
    _focus.requestFocus();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final palette = GlassPalette(isDark: widget.isDark, accent: widget.accentColor);
    final textColor = palette.textPrimary;
    final mutedColor = palette.textMuted;
    final bgColor = palette.isDark ? AppColors.surface : AppColors.surfaceLight;
    final accent = widget.accentColor;

    final resolvedDate = _resolvedDate;
    final detectedDate = _detectedDate;
    final detectedPriority = _detectedPriority;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: palette.glassBorder, width: 0.5),
            left: BorderSide(color: palette.glassBorder, width: 0.5),
            right: BorderSide(color: palette.glassBorder, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Detected token preview ────────────────────────────────────
            if (detectedDate != null || detectedPriority != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (detectedDate != null && !_dateSuppressed)
                      _TokenChip(
                        label: _friendlyDate(detectedDate),
                        icon: Icons.event_rounded,
                        color: accent,
                        onRemove: () => setState(() => _dateSuppressed = true),
                      ),
                    if (detectedPriority != null)
                      _TokenChip(
                        label: _priorityLabel(detectedPriority),
                        icon: Icons.flag_rounded,
                        color: _priorityColor(detectedPriority),
                        onRemove: null,
                      ),
                  ],
                ),
              ),

            // ── Text input ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          _save();
                        }
                      },
                      child: TextField(
                        controller: _titleCtrl,
                        focusNode: _focus,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What needs to be done? (try: p1, tomorrow)',
                          hintStyle: TextStyle(color: mutedColor, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _save(),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  // Send button
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _titleCtrl.text.trim().isEmpty
                            ? palette.border
                            : accent,
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────
            Divider(height: 1, color: palette.border),

            // ── Manual action bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  // Date
                  _ActionButton(
                    icon: Icons.calendar_today_rounded,
                    label: resolvedDate != null ? _friendlyDate(resolvedDate) : null,
                    color: resolvedDate != null ? accent : mutedColor,
                    onTap: _pickDate,
                    onClear: resolvedDate != null
                        ? () => setState(() {
                              _manualDate = null;
                            })
                        : null,
                    palette: palette,
                  ),
                  const SizedBox(width: 8),
                  // Priority chips
                  ..._buildPriorityChips(palette, accent),
                  const Spacer(),
                  // Notes hint
                  Icon(Icons.notes_rounded, size: 18, color: mutedColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPriorityChips(GlassPalette palette, Color accent) {
    return TaskPriority.values.map((p) {
      final isSelected = _manualPriority == p;
      final isDetected = _detectedPriority == p && _manualPriority == null;
      final color = _priorityColor(p);
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: () => setState(() {
            _manualPriority = isSelected ? null : p;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isSelected || isDetected)
                  ? color.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isSelected || isDetected) ? color : palette.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              _priorityLabel(p),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: (isSelected || isDetected) ? color : palette.textMuted,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return 'P3';
      case TaskPriority.medium:
        return 'P2';
      case TaskPriority.high:
        return 'P1';
      case TaskPriority.urgent:
        return 'P!';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
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
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.palette,
    this.label,
    this.onClear,
  });

  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: label != null ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: label != null ? color.withOpacity(0.5) : palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label!,
                  style: TextStyle(
                      fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close, size: 12, color: color),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
