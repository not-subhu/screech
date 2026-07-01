import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends ConsumerStatefulWidget {
  const AddTaskSheet({super.key});

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueAt;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.sakura,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.sakura,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    setState(() {
      _dueAt = time == null
          ? date
          : DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    await ref.read(tasksProvider.notifier).addTask(
          title: title,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          dueAt: _dueAt,
          priority: _priority,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('New Quest', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // Title field
          _field(
            controller: _titleCtrl,
            hint: 'What needs to be done? ✦',
            autofocus: true,
          ),
          const SizedBox(height: 10),
          // Notes field
          _field(
            controller: _notesCtrl,
            hint: 'Notes (optional)',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // Priority selector
          Text('Priority',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Row(
            children: TaskPriority.values
                .map((p) => _PriorityChip(
                      priority: p,
                      selected: _priority == p,
                      onTap: () => setState(() => _priority = p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          // Due date
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          _dueAt == null
                              ? 'Set due date / time'
                              : DateFormat('MMM d, h:mm a').format(_dueAt!),
                          style: TextStyle(
                            color: _dueAt == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_dueAt != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _dueAt = null),
                  child: const Icon(Icons.close,
                      color: AppColors.textMuted, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sakura,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Add Quest  ✦',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      autofocus: autofocus,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 15),
        filled: true,
        fillColor: AppColors.bgDeep,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sakura, width: 1.5),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  Color get _color {
    switch (priority) {
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

  String get _label {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Med';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return '🔥';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _color.withOpacity(0.25) : AppColors.bgDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _color : AppColors.surfaceBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          _label,
          style: TextStyle(
            color: selected ? _color : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
